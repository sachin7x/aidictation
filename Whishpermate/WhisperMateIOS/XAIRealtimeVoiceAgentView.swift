import SwiftUI

struct XAIRealtimeVoiceAgentView: View {
    @StateObject private var conversation = XAIRealtimeVoiceAgentConversation()
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                header

                Text("Live Voice sends your microphone audio and conversation content to xAI for real-time processing. Your existing offline dictation settings are unchanged.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)

                conversationTimeline

                if conversation.state == .connected || conversation.state == .speaking {
                    composer
                }

                primaryControl
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Voice Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Voice", selection: $conversation.voice) {
                            ForEach(XAIRealtimeVoice.allCases) { voice in
                                Text(voice.rawValue).tag(voice)
                            }
                        }
                    } label: {
                        Image(systemName: "waveform")
                            .accessibilityLabel("Choose voice")
                    }
                    .disabled(conversation.isActive && conversation.state == .connecting)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onDisappear { conversation.stop() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.14))
                    .frame(width: 46, height: 46)
                Image(systemName: "waveform")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Grok Voice")
                    .font(.headline)
                Text(conversation.statusText)
                    .font(.caption)
                    .foregroundColor(conversation.state.isFailure ? .red : .secondary)
                    .lineLimit(2)
            }

            Spacer()

            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
                .accessibilityLabel(conversation.statusText)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var conversationTimeline: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if conversation.messages.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "mic.and.signal.meter")
                            .font(.system(size: 34))
                            .foregroundColor(.secondary)
                        Text("Start a live conversation")
                            .font(.headline)
                        Text("Speak naturally in English, Hindi, or Hinglish. You can interrupt Grok or type a message at any time.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 44)
                    .padding(.horizontal, 24)
                }

                ForEach(conversation.messages) { message in
                    messageBubble(message)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 14)
    }

    private func messageBubble(_ message: XAIRealtimeVoiceMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 42) }

            VStack(alignment: .leading, spacing: 5) {
                Text(message.role == .user ? "You" : "Grok")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(message.text.isEmpty ? "…" : message.text)
                    .font(.body)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                message.role == .user
                    ? Color.accentColor.opacity(0.14)
                    : Color(uiColor: .tertiarySystemGroupedBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if message.role == .assistant { Spacer(minLength: 42) }
        }
        .frame(maxWidth: .infinity)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Send a text message…", text: $draft)
                .lineLimit(1)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.send)
                .onSubmit(sendText)

            Button(action: sendText) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 18)
    }

    private var primaryControl: some View {
        Button {
            if conversation.isActive {
                conversation.stop()
            } else {
                conversation.start()
            }
        } label: {
            Label(
                conversation.isActive ? "End conversation" : "Start conversation",
                systemImage: conversation.isActive ? "stop.fill" : "mic.fill"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundColor(.white)
            .background(conversation.isActive ? Color.red : Color.accentColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(conversation.state == .connecting)
        .accessibilityHint("Starts or ends a live voice conversation with Grok.")
    }

    private var statusColor: Color {
        switch conversation.state {
        case .disconnected: .secondary
        case .connecting: .orange
        case .connected: .green
        case .speaking: .blue
        case .failed: .red
        }
    }

    private func sendText() {
        let value = draft
        draft = ""
        conversation.sendText(value)
    }
}

private extension XAIRealtimeVoiceAgentConversation.State {
    var isFailure: Bool {
        if case .failed = self { return true }
        return false
    }
}
