# xAI Realtime Voice Agent

AI Dictation's iOS app exposes an optional, full-duplex voice conversation screen backed by the xAI Voice Agent API. This is a separate experience from the existing offline/cloud dictation pipeline; it does not change the selected transcription provider or keyboard dictation behavior.

## Request flow

1. The signed-in iOS app obtains a fresh Supabase access token from `AuthManager`.
2. The app calls `POST /api/voice/xai/session` with that token.
3. The route validates the token with Supabase and reserves one per-user token issuance.
4. The server calls xAI's `POST /v1/realtime/client_secrets` endpoint using the server-only `XAI_API_KEY`, requesting a 300-second ephemeral secret.
5. The app uses that ephemeral secret as the `xai-client-secret.<secret>` WebSocket subprotocol when connecting to `wss://api.x.ai/v1/realtime?model=grok-voice-latest`.
6. Microphone audio is converted to mono 24 kHz PCM16 and streamed to xAI. Assistant audio is decoded and played locally.

The permanent xAI key is never included in the iOS bundle, plist, client request, or WebSocket handshake.

## Required deployment configuration

Set `XAI_API_KEY` as a server-side environment variable for the Next.js deployment. Do not add it to `Secrets.plist`, `Secrets.template.plist`, build settings, or any mobile configuration.

Apply migration `202611190001_xai_voice_session_rate_limit.sql` before enabling the endpoint. It creates a database-backed quota of six ephemeral-token issuances per authenticated user per minute. The table is not directly accessible to client roles.

The route also requires the existing Supabase server environment:
- `SUPABASE_URL` (or `NEXT_PUBLIC_SUPABASE_URL`)
- `SUPABASE_ANON_KEY` (or `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`)

## Privacy and lifecycle

The voice screen explicitly tells users that live microphone audio and conversation content are sent to xAI. The feature requires an authenticated account and microphone permission. Ephemeral credentials are short-lived and responses are marked `no-store`. Stopping or dismissing the screen stops microphone capture, playback, and the WebSocket.

Offline dictation remains on-device and is not routed through xAI. Live voice is an opt-in cloud conversation, not a silent change to the dictation provider.

## Verification checklist

- Apply the Supabase migration in the target environment.
- Configure `XAI_API_KEY` in the server deployment.
- Sign in to the iOS app and start a voice session on a physical iPhone.
- Verify unauthenticated requests return 401 and the seventh token request in a rolling minute returns 429.
- Verify microphone permission denial produces a recoverable UI error.
- Verify stop/dismiss tears down the audio engine and WebSocket.
- Confirm the app binary and mobile configuration contain no xAI permanent API key.
