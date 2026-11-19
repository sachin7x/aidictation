import AVFoundation
import Combine
import Foundation
import WhisperMateShared

struct XAIRealtimeVoiceMessage: Identifiable, Equatable {
    enum Role: String {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    var text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}

enum XAIRealtimeVoice: String, CaseIterable, Identifiable {
    case eve = "Eve"
    case ara = "Ara"
    case rex = "Rex"
    case sal = "Sal"
    case leo = "Leo"

    var id: String { rawValue }
    var apiValue: String { rawValue.lowercased() }
}

@MainActor
final class XAIRealtimeVoiceAgentConversation: ObservableObject {
    enum State: Equatable {
        case disconnected
        case connecting
        case connected
        case speaking
        case failed(String)
    }

    @Published private(set) var state: State = .disconnected
    @Published private(set) var messages: [XAIRealtimeVoiceMessage] = []
    @Published var voice: XAIRealtimeVoice = .eve {
        didSet {
            guard oldValue != voice, state == .connected || state == .speaking else { return }
            sendSessionUpdate()
        }
    }

    private let audioEngine = XAIRealtimeVoiceAudioEngine()
    private var webSocket: URLSessionWebSocketTask?
    private var connectionTask: Task<Void, Never>?
    private var connectionTimeoutTask: Task<Void, Never>?
    private var assistantMessageID: UUID?
    private var userMessageID: UUID?
    private var hasStartedAudio = false

    var isActive: Bool {
        switch state {
        case .connecting, .connected, .speaking: true
        case .disconnected, .failed: false
        }
    }

    var statusText: String {
        switch state {
        case .disconnected: "Ready to connect"
        case .connecting: "Connecting to Grok…"
        case .connected: "Listening"
        case .speaking: "Grok is speaking"
        case .failed(let message): message
        }
    }

    func start() {
        guard state == .disconnected || isFailed else { return }
        state = .connecting
        messages.removeAll()
        assistantMessageID = nil
        hasStartedAudio = false
        userMessageID = nil

        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 45_000_000_000)
            guard let self, self.state == .connecting else { return }
            self.fail("The voice connection timed out. Check your connection and try again.")
        }

        connectionTask?.cancel()
        connectionTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.connect()
            } catch is CancellationError {
                return
            } catch {
                self.fail(error.localizedDescription)
            }
        }
    }

    func stop() {
        connectionTask?.cancel()
        connectionTask = nil
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = nil
        audioEngine.stop()
        hasStartedAudio = false
        assistantMessageID = nil
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        state = .disconnected
    }

    func sendText(_ text: String) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, state == .connected || state == .speaking else { return }

        if state == .speaking {
            sendJSON(["type": "response.cancel"])
            audioEngine.interruptPlayback()
            state = .connected
        }

        messages.append(XAIRealtimeVoiceMessage(role: .user, text: value))
        sendJSON([
            "type": "conversation.item.create",
            "item": [
                "type": "message",
                "role": "user",
                "content": [["type": "input_text", "text": value]],
            ],
        ])
        sendJSON([
            "type": "response.create",
            "response": ["modalities": ["text", "audio"]],
        ])
    }

    private var isFailed: Bool {
        if case .failed = state { return true }
        return false
    }

    private func connect() async throws {
        try await requestMicrophonePermission()
        try Task.checkCancellation()

        let accessToken = try await AuthManager.shared.accessToken()
        try Task.checkCancellation()
        let token = try await fetchEphemeralToken(accessToken: accessToken)
        try Task.checkCancellation()

        var components = URLComponents()
        components.scheme = "wss"
        components.host = "api.x.ai"
        components.path = "/v1/realtime"
        components.queryItems = [URLQueryItem(name: "model", value: "grok-voice-latest")]
        guard let socketURL = components.url else {
            throw VoiceAgentError.invalidEndpoint
        }

        // URLSessionWebSocketTask supports the xAI client-secret subprotocol.
        // The permanent xAI API key never leaves the server.
        let socket = URLSession.shared.webSocketTask(
            with: socketURL,
            protocols: ["xai-client-secret.\(token)"]
        )
        webSocket = socket
        socket.resume()
        receiveNext()
    }

    private func requestMicrophonePermission() async throws {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            return
        case .denied:
            throw VoiceAgentError.microphonePermissionDenied
        case .undetermined:
            let granted = await withCheckedContinuation { continuation in
                session.requestRecordPermission { continuation.resume(returning: $0) }
            }
            guard granted else { throw VoiceAgentError.microphonePermissionDenied }
        @unknown default:
            throw VoiceAgentError.microphonePermissionDenied
        }
    }

    private func fetchEphemeralToken(accessToken: String) async throws -> String {
        guard let configuredURL = SecretsLoader.getValue(for: "AUTH_WEB_URL"),
              var components = URLComponents(string: configuredURL),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              components.host != nil
        else {
            throw VoiceAgentError.serverNotConfigured
        }

        components.path = "/api/voice/xai/session"
        components.query = nil
        components.fragment = nil
        guard let endpoint = components.url else {
            throw VoiceAgentError.serverNotConfigured
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw VoiceAgentError.invalidServerResponse
        }

        switch http.statusCode {
        case 200..<300:
            break
        case 401:
            throw VoiceAgentError.authenticationRequired
        case 429:
            throw VoiceAgentError.rateLimited
        case 503:
            throw VoiceAgentError.serverNotConfigured
        default:
            throw VoiceAgentError.tokenRequestFailed(http.statusCode)
        }

        let payload = try JSONDecoder().decode(ClientSecretResponse.self, from: data)
        let token = payload.clientSecret.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard token.count >= 16 else { throw VoiceAgentError.invalidServerResponse }
        return token
    }

    private func receiveNext() {
        guard let socket = webSocket else { return }
        socket.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let message):
                    self.handle(message)
                    self.receiveNext()
                case .failure(let error):
                    guard self.isActive else { return }
                    self.fail(error.localizedDescription)
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let data: Data
        switch message {
        case .string(let text):
            guard let encoded = text.data(using: .utf8) else { return }
            data = encoded
        case .data(let value):
            data = value
        @unknown default:
            return
        }

        guard let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = event["type"] as? String
        else { return }

        switch type {
        case "session.created":
            sendSessionUpdate()

        case "session.updated":
            connectionTimeoutTask?.cancel()
            connectionTimeoutTask = nil
            guard !hasStartedAudio else { return }
            do {
                let socket = webSocket
                try audioEngine.start { [weak self, socket] base64Audio in
                    let payload = #"{"type":"input_audio_buffer.append","audio":"\#(base64Audio)"}"#
                    socket?.send(.string(payload)) { error in
                        guard let error else { return }
                        Task { @MainActor [weak self] in
                            self?.handleTransportError(error)
                        }
                    }
                }
                hasStartedAudio = true
                state = .connected
            } catch {
                fail(error.localizedDescription)
            }

        case "input_audio_buffer.speech_started":
            audioEngine.interruptPlayback()
            if state == .speaking { state = .connected }

        case "conversation.item.input_audio_transcription.updated":
            if let transcript = event["transcript"] as? String {
                updateUserTranscript(transcript, isFinal: false)
            }

        case "conversation.item.input_audio_transcription.completed":
            if let transcript = event["transcript"] as? String {
                updateUserTranscript(transcript, isFinal: true)
            }

        case "response.created":
            state = .speaking
            let message = XAIRealtimeVoiceMessage(role: .assistant, text: "")
            assistantMessageID = message.id
            messages.append(message)

        case "response.output_audio_transcript.delta", "response.audio_transcript.delta":
            if let delta = event["delta"] as? String, !delta.isEmpty {
                appendAssistantText(delta)
            }

        case "response.output_audio.delta", "response.audio.delta":
            if let audio = event["delta"] as? String {
                audioEngine.playAudioDelta(base64: audio)
            }

        case "response.output_audio_transcript.done":
            if let transcript = event["transcript"] as? String {
                replaceAssistantText(transcript)
            }

        case "response.output_audio.done":
            break

        case "response.done":
            if state == .speaking { state = .connected }
            assistantMessageID = nil

        case "error":
            let detail = (event["error"] as? [String: Any])?["message"] as? String
            if let detail, !detail.isEmpty {
                // API errors can be recoverable; surface the message without
                // dumping the event payload or any ephemeral credential.
                if state == .connecting {
                    fail(detail)
                }
            }

        default:
            break
        }
    }

    private func sendSessionUpdate() {
        sendJSON([
            "type": "session.update",
            "session": [
                "voice": voice.apiValue,
                "instructions": "You are AI Dictation's live voice assistant. Be concise, accurate, and warm. Understand Hindi, English, and natural Hinglish. Reply in the language the user is speaking unless they ask otherwise.",
                "turn_detection": ["type": "server_vad"],
                "audio": [
                    "input": [
                        "format": ["type": "audio/pcm", "rate": 24000],
                        "transcription": ["model": "grok-transcribe"],
                    ],
                    "output": [
                        "format": ["type": "audio/pcm", "rate": 24000],
                    ],
                ],
            ],
        ])
    }

    private func sendJSON(_ payload: [String: Any]) {
        guard let webSocket,
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8)
        else { return }

        webSocket.send(.string(text)) { [weak self] error in
            guard let error else { return }
            Task { @MainActor [weak self] in
                self?.handleTransportError(error)
            }
        }
    }

    private func updateUserTranscript(_ text: String, isFinal: Bool) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }

        if let id = userMessageID,
           let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].text = value
        } else {
            let message = XAIRealtimeVoiceMessage(role: .user, text: value)
            userMessageID = message.id
            messages.append(message)
        }

        if isFinal { userMessageID = nil }
    }

    private func appendAssistantText(_ text: String) {
        guard let id = assistantMessageID,
              let index = messages.firstIndex(where: { $0.id == id })
        else {
            let message = XAIRealtimeVoiceMessage(role: .assistant, text: text)
            assistantMessageID = message.id
            messages.append(message)
            return
        }
        messages[index].text += text
    }

    private func replaceAssistantText(_ text: String) {
        guard let id = assistantMessageID,
              let index = messages.firstIndex(where: { $0.id == id })
        else { return }
        messages[index].text = text
    }

    private func handleTransportError(_ error: Error) {
        guard isActive else { return }
        fail(error.localizedDescription)
    }

    private func fail(_ message: String) {
        connectionTask?.cancel()
        connectionTask = nil
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = nil
        audioEngine.stop()
        hasStartedAudio = false
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        state = .failed(message)
    }
}

private struct ClientSecretResponse: Decodable {
    struct ClientSecret: Decodable {
        let value: String
    }

    let clientSecret: ClientSecret

    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
    }
}

private enum VoiceAgentError: LocalizedError {
    case invalidEndpoint
    case serverNotConfigured
    case invalidServerResponse
    case authenticationRequired
    case microphonePermissionDenied
    case rateLimited
    case tokenRequestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            "The xAI voice endpoint is invalid."
        case .serverNotConfigured:
            "Live voice is not configured on the server yet."
        case .invalidServerResponse:
            "The voice session server returned an invalid response."
        case .authenticationRequired:
            "Sign in to AI Dictation before starting a live voice session."
        case .microphonePermissionDenied:
            "Microphone access is disabled. Allow it in iPhone Settings to use live voice."
        case .rateLimited:
            "Too many voice sessions were started. Wait a minute and try again."
        case .tokenRequestFailed(let status):
            "Could not start the xAI voice session (HTTP \(status))."
        }
    }
}

@MainActor
private final class XAIRealtimeVoiceAudioEngine {
    private static let sampleRate = 24_000.0
    private static let outputFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: sampleRate,
        channels: 1,
        interleaved: false
    )!

    private let converter = RealtimePCMConverter()
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var hasMicrophoneTap = false

    func start(onAudio: @escaping (String) -> Void) throws {
        guard engine == nil else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
        try session.setActive(true)

        let audioEngine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: Self.outputFormat)

        // Enable echo cancellation and automatic gain control where supported.
        // The voice-chat session remains usable if a device/route rejects this option.
        do {
            try audioEngine.inputNode.setVoiceProcessingEnabled(true)
            audioEngine.inputNode.isVoiceProcessingAGCEnabled = true
            audioEngine.inputNode.isVoiceProcessingBypassed = false
        } catch {
            // Continue without hardware echo cancellation on unsupported routes.
        }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0 else {
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            throw VoiceAgentError.invalidServerResponse
        }

        let pcmConverter = converter
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { buffer, _ in
            guard let pcm = pcmConverter.chunk(from: buffer) else { return }
            onAudio(pcm.base64EncodedString())
        }
        hasMicrophoneTap = true

        do {
            audioEngine.prepare()
            try audioEngine.start()
            player.play()
            self.engine = audioEngine
            self.playerNode = player
        } catch {
            inputNode.removeTap(onBus: 0)
            hasMicrophoneTap = false
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            throw error
        }
    }

    func playAudioDelta(base64: String) {
        guard let audioData = Data(base64Encoded: base64),
              audioData.count >= MemoryLayout<Int16>.size,
              audioData.count.isMultiple(of: MemoryLayout<Int16>.size),
              let engine, engine.isRunning,
              let playerNode
        else { return }

        let frameCount = audioData.count / MemoryLayout<Int16>.size
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: Self.outputFormat,
            frameCapacity: AVAudioFrameCount(frameCount)
        ), let channel = buffer.floatChannelData?[0] else { return }

        buffer.frameLength = AVAudioFrameCount(frameCount)
        audioData.withUnsafeBytes { rawBuffer in
            let samples = rawBuffer.bindMemory(to: Int16.self)
            for index in 0..<frameCount {
                channel[index] = Float(samples[index]) / 32_768.0
            }
        }

        playerNode.scheduleBuffer(buffer)
        if !playerNode.isPlaying { playerNode.play() }
    }

    func interruptPlayback() {
        guard let playerNode else { return }
        playerNode.stop()
        playerNode.play()
    }

    func stop() {
        guard let engine else { return }
        if hasMicrophoneTap {
            engine.inputNode.removeTap(onBus: 0)
            hasMicrophoneTap = false
        }
        playerNode?.stop()
        if engine.isRunning { engine.stop() }
        self.engine = nil
        playerNode = nil
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
}
