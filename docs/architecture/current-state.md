# Current State — Flow Platform Foundation

## VERIFIED
- The repository provides native clients for macOS, Windows, iPhone/iPad, and Android.
- The repository documents offline recognition, optional cloud transcription/cleanup, personal vocabulary, replacements, writing rules, spoken shortcuts, and local history where supported.
- Apple clients live under `Whishpermate/`; its README identifies macOS, iPhone/iPad, an iOS keyboard extension, shared Apple code, Xcode, and Fastlane.
- Windows is documented through `AIDictation.Windows/AIDictation.sln`.
- Android is documented through `AIDictationAndroid/gradlew assembleDebug`.
- No existing JavaScript `package.json` or GitHub Actions workflow was returned by repository code search on the inspected default branch.

## INFERRED
- Native applications should remain device-side clients rather than being replaced by a web wrapper.
- Web/API services should be added behind explicit contracts and trust boundaries.
- Authentication, billing, sync, and verifier services belong on the server side.

## UNKNOWN
- Exact implementation details of speech capture, recognition, persistence, networking, authentication, and billing require deeper source inspection.
- Native buildability and production CI state have not been executed or independently verified here.

## Boundary
This branch adds the platform foundation without rewriting native clients. Further integration must be based on source inspection and executable verification.
