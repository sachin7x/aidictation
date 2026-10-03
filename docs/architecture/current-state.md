# Current State — Flow Platform Foundation

## VERIFIED

Repository tree inspection shows an established native product and an existing CI/release system.

Native clients:
- Apple: macOS, iPhone/iPad, iOS keyboard, shared Apple code, Live Activity.
- Windows: .NET 8 client with audio capture, transcription, cleanup, auth, history, settings, hotkeys/input, local Whisper.
- Android: Kotlin client with Room persistence, Supabase auth, subscription/usage accounting, transcription API/repository, local Parakeet, command client, overlay/accessibility insertion.

Shared/product infrastructure already present:
- Supabase Auth and profiles.
- Keychain-backed Apple auth storage.
- Existing subscription/word-usage accounting.
- Existing referral/AppSumo Supabase migrations/functions.
- Native dictionary/context rules/shortcuts/style-like controls.
- Native transcription pipelines with offline/cloud modes and optional cleanup.
- Extensive audio recovery/checkpoint/fencing contracts.

Existing GitHub Actions workflows already cover Android build/release, iOS App Store Connect, macOS release/UI contracts, Windows build/E2E/UI/release, transcription contracts, and audio recovery.

The Flow-platform branch additionally contains:
- web foundation
- shared platform contracts
- additive Supabase schema for dictionary/snippets/styles/devices/sync/usage/entitlements/verification
- server auth/sync boundaries
- independent verifier contract
- CATCH C0–C6 regression specification

## INFERRED

- The new platform should converge existing native identity and transcription contracts rather than replace them.
- Supabase remains the natural identity/control-plane boundary because native clients already use it.
- Device-native audio capture and offline recognition should remain local; server services should provide sync, entitlements, transforms/meeting services, and verification.
- Existing native CI should be extended rather than duplicated.

## UNKNOWN

- Exact production database schema outside the migrations committed to this repository.
- Runtime compatibility of the new web/server code until CI executes it.
- Cross-platform parity of every future Flow feature.
- Production implementation of billing, transforms, Notetaker, MCP, and verifier-backed commands.

## Verification rule

No production-readiness claim is made until executable CI/build evidence exists for the affected surfaces.
