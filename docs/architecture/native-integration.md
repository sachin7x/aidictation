# Native integration map

## VERIFIED from source inspection

### Apple
The shared Apple layer contains authentication, Supabase access, transcription orchestration, dictionary/context managers, history, subscription management, keychain-backed auth storage, and realtime transcription support. macOS additionally contains CommandModeManager, application-context helpers, clipboard insertion, hotkey handling, local Parakeet transcription, and VAD.

### Windows
The Windows client contains AuthService, TranscriptionService, LanguagePostProcessService, HistoryService, SettingsService, hotkey/input services, local Whisper support, audio recovery/checkpointing, and usage reporting.

### Android
The Android client contains Supabase-backed authentication, subscription/usage accounting, Room persistence, transcription API/repository layers, local Parakeet support, command client, language post-processing, overlay/accessibility insertion, and tests for migration/recovery/transport behavior.

## Integration decision

Do not duplicate these pipelines in the web server. The platform server should provide identity, synchronized user configuration, entitlements, provider policy, transforms/meeting services, and verification. Device-native audio capture and offline recognition remain on-device.

## Critical convergence point

The existing native transcription architecture already snapshots vocabulary, replacements, expansions, language settings, context rules, and cleanup configuration before an attempt. The new API contract must preserve that context boundary rather than reconstructing it after audio upload.

## Unknown

Exact cross-platform parity of all feature flags and provider configuration still requires source-level diffing of the remaining client files and executable builds.
