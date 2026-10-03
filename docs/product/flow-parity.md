# Flow Product Parity Matrix

This is the implementation ledger for clean-room functional parity with the publicly documented Wispr Flow product surface. It does not copy proprietary source, branding, or private implementation.

| Capability | Public reference | Current A-Anie state | Evidence required |
|---|---|---|---|
| Cross-platform dictation | Public Wispr Flow features/docs | Native Apple/Windows/Android clients exist; shared web control plane is present | Native end-to-end insertion tests on each supported client |
| Smart formatting | Public features/docs | Native transcription contracts exist; web configuration surface is incomplete | Formatting corpus covering punctuation, lists, corrections |
| Backtrack/self-correction | Public features/docs | Native transcription pipeline is the execution boundary | Deterministic regression corpus |
| Filler removal | Public features/docs | Cleanup boundary exists; provider-backed web transforms exist | Cleanup fixtures with raw-transcript preservation |
| Dictionary | Public docs | Authenticated workspace exists | CRUD + sync + native adapter tests |
| Snippets | Public docs | Authenticated workspace exists | Trigger matching + CRUD + sync tests |
| Styles | Public docs | Workspace surface added in this branch | Category/style persistence + native adapter tests |
| Transforms | Public docs | Authenticated API/UI exists; provider is external | Provider contract + original-text preservation + failure tests |
| Command Mode | Public docs | Shared command contract/verifier architecture exists | Independent verifier + native execution evidence |
| Notetaker | Public docs | Meeting persistence/schema and UI boundary exist | Native capture → transcript → summary → action-item ingestion |
| Meeting consent/privacy | Public privacy docs | Security/privacy boundary exists; capture is not production-complete | Consent, retention, access-control and deletion tests |
| MCP meeting access | Public MCP docs | Contract boundary exists; production transport is gated | Read-only MCP integration tests |
| Shared dictionary/snippets | Public collaboration docs | Database foundation exists | Team membership, authorization, sharing and sync tests |
| Usage/admin | Public collaboration docs | Entitlement/usage schema exists | Metering and authorization tests |
| Billing | Public commercial surface | Razorpay signature boundary exists | Production webhook + entitlement mapping evidence |
| Developer workflows | Public developer docs | Developer page and native contracts exist | Syntax/file-tagging corpus and platform tests |
| Offline/local recognition | Existing native architecture | Native local recognition remains device-side | Offline execution tests on supported clients |

## Verification policy

A feature is VERIFIED only when its implementation and observable behavior have execution evidence. Documentation, mocks, static pages, or an API returning a success-shaped response are not sufficient.

Every consequential agent/action boundary should have:
1. normal-path test,
2. adversarial test,
3. independent verifier,
4. explicit PASS, FAIL, or UNKNOWN result.

UNKNOWN is never reward-positive.

## Current priority

1. Authentication and workspace interaction.
2. Dictionary/snippets/styles CRUD and sync.
3. Dictation + cleanup contracts and regression corpus.
4. Command Mode execution + verifier.
5. Notetaker ingestion, privacy, and meeting search.
6. Read-only MCP transport.
7. Team sharing, usage, billing and enterprise controls.
8. Native release integration and final CATCH/C0-C6 verification.