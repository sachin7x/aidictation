# Native integration contract

The native applications remain the execution layer for microphone capture, offline recognition, foreground-app insertion, accessibility/clipboard APIs, local recovery and platform-specific permissions.

The web/server platform owns:
- identity and session synchronization
- dictionary, snippets and styles synchronization
- server-owned usage and entitlement state
- transforms
- meeting persistence and retrieval
- capability-scoped MCP
- independent verification events

A native adapter should:
1. authenticate with the existing Supabase session;
2. identify itself with a stable device ID and platform;
3. upload revisioned dictionary/snippet/style changes;
4. consume /api/sync?cursor=... until caught up;
5. never treat a client-side paid flag as authoritative;
6. preserve raw recognition output when cleanup/transforms fail;
7. treat command completion as successful only after native execution acknowledgement and verifier evidence.

Existing Apple, Windows and Android implementations already provide the device-side audio/transcription and subscription primitives this adapter should wrap.
