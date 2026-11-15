# V4.1 P01 — Repository Audit & Traceability Baseline
Date: 2026-11-15
Branch: feat/typing-presence
Audit source: GitHub tree + source/migration reads (remote repository inspection only)

## Audit limits
This is a source inspection, not a local checkout. No Flutter SDK execution, dependency resolution, SQL application, Supabase live checks, Android/browser/device testing or CI run was available. No compile/runtime status is inferred.

## Repository inventory
- Mobile: Flutter app in `apps/mobile`, GoRouter, Supabase Flutter, flutter_webrtc, Riverpod dependencies.
- Mobile routes currently declared: `/`, `/auth`, `/friends`, `/messages`.
- Mobile feature code: friends, messaging (two ChatRepository implementations), presence controller/repository, call models/repository/incoming screen/WebRTC controller.
- Backend schema: six migrations `0001_call_sessions` through `0006_profiles`.
- Product specifications: V4.1 hard lock, screen/button blueprint, advanced add-ons, master roadmap and domain docs.
- No web/PWA or admin application source tree currently appears in the audited branch.
- No CI workflow, automated test files, or deployment manifests were found in the audited tree.

## Confirmed code/spec mismatches and risks

### P01-01 — Authentication violates V4.1 Google-only contract (HIGH)
- `AuthScreen` currently offers email/password sign-in and email/password signup.
- V4.1 permits only one Google OAuth entry point for both new and returning users.
- Required: replace email/password UI/flows with Google OAuth; configure state/nonce/PKCE and platform callback/deep-link; validate Supabase provider config and session handling. Do not mark verified until configured and tested.

### P01-02 — Messaging repository duplication and inconsistent APIs (HIGH)
- `chat_repository.dart` and `chat_repository_v2.dart` both define `ChatRepository` with different constructor/method signatures.
- Current chat thread imports v2; older repository remains and has a different subscribe API.
- Canonicalize to one repository and one conversation/thread contract; remove duplicate only after references are checked.
- Conversation IDs are generated client-side from sorted user IDs; server must independently validate canonical participant identity and prevent caller-controlled conversation spoofing.

### P01-03 — Plaintext message body conflicts with E2EE scope (CRITICAL DESIGN GAP)
- `chat_messages.body` is plaintext text and current RPC stores raw message body.
- V4.1 requires genuine E2EE and no universal Admin plaintext access.
- Required redesign: ciphertext/envelope + version/algorithm + sender device/key identifiers + nonce/metadata; key lifecycle and device trust/recovery; server stores/relays ciphertext; client encryption/decryption; safe report evidence uses separately scoped user-authorized plaintext capture. Do not label current chat E2EE.

### P01-04 — Chat authorization and realtime authorization not proven (HIGH)
- Migration participant SELECT policy exists; direct insert/update/delete policies are denied and writes use RPCs.
- Need inspect all grants/RPC security-definer ownership/search_path and ensure participant + friendship + block + conversation consistency checks in every write/status action.
- Realtime row changes are filtered by conversation ID but the client channel naming/private authorization policy is not evidenced. Typing uses broadcast; authenticated private channel authorization and membership enforcement must be implemented and tested.
- Do not expose message body in telemetry, logs, admin dashboard or notification payload.

### P01-05 — Social feature gaps (HIGH)
- Existing friends screen/repository supports search, friend list, incoming requests, send/respond/remove/block.
- Unified Connections tabs (friends/requests/followers/following/discover), outgoing request list/cancel, follow graph, privacy/visibility and cross-feature block enforcement are not fully evidenced.
- Search query is interpolated into PostgREST OR/ILIKE filter; escape/validate reserved filter syntax and enforce rate/visibility policy server-side.

### P01-06 — Calling and matching are scaffolds, not verified (CRITICAL)
- Call models/repository/incoming UI/WebRTC controller exist.
- No complete matchmaking queue/session integration, private-call accept lifecycle, signaling server authorization, TURN credential flow or two-device/network evidence established.
- Call UI must not imply call/match works until the complete secure flow is integrated.

### P01-07 — Routes and user journeys incomplete (HIGH)
- Current router has only home/auth/friends/messages; chat thread opens via Navigator push rather than canonical named route.
- V4.1 screen catalog S00–S20, website W00–W14 and admin A00–A18 are product requirements, not implemented routes.
- Need route registry/deep-link policy, auth/age/consent guards, safe redirects and route tests.

### P01-08 — Initialization/environment and lifecycle (HIGH)
- Source references Supabase initialization state; startup/config handling and environment separation require review.
- Need non-secret configuration strategy, dev/staging/prod isolation, no keys in source, session lifecycle, logout cleanup, crash/error reporting redaction.
- App README/pubspec do not prove reproducible build or CI.

### P01-09 — Data migration/RLS/test status (HIGH)
- Six SQL migrations exist, but no evidence they have been applied or validated on staging.
- Required: migration ordering/rollback strategy, SQL lint/validation, RLS tests as anon/authenticated/participant/nonparticipant/blocked users, RPC privilege review, data constraints/indexes and staging apply evidence.

### P01-10 — Web/Admin/operations/launch (BLOCKER)
- No web/PWA or Admin/Ops code found in current tree.
- No CI, release artifacts, monitoring, backup/restore, incident/rollback drills, beta or deployment evidence.
- PR #1 is draft/unmerged; no production action is authorized.

## V4.1 traceability baseline (screen/action families → current evidence)

| Scope family | Existing source evidence | Current truth |
|---|---|---|
| S00 startup | main.dart/app.dart | partial shell; config/lifecycle unverified |
| S01 Google auth | AuthScreen | email/password present; V4.1 mismatch |
| S02 onboarding/age/consent | none found | SPECIFIED only |
| S03 home | HomeScreen | partial links; many actions placeholder |
| S04–S05 matching/stranger video | none found | SPECIFIED only |
| S06 post-match | none found | SPECIFIED only |
| S07–S08 profile | profiles migration/trigger | schema fragment only |
| S09–S10 discover/connections | Friends screen/repository | partial friends/search |
| S11 inbox | messaging screen/thread | partial friend-based inbox |
| S12 E2EE chat | chat UI/repositories/migration | plaintext foundation; NOT E2EE |
| S13 calls | call repository/incoming/WebRTC scaffold | incomplete, unverified |
| S14 notifications | preferences migration/docs | preferences/schema only |
| S15 settings | none found | SPECIFIED only |
| S16 safety/help | block fragments/docs | incomplete |
| S17 wallet/payments | none found | SPECIFIED only |
| S18 rewards/referrals | none found | SPECIFIED only |
| S19 media viewer | none found | SPECIFIED only |
| S20 dialogs/errors | ad hoc SnackBars | no global system |
| W00–W14 Website/PWA | no source tree | SPECIFIED only |
| A00–A18 Admin/Ops | no source tree | SPECIFIED only |

## P01 exit criteria
- [x] Repository file inventory recorded.
- [x] Current route and domain source inventory recorded.
- [x] Major V4.1 mismatches/risk areas documented.
- [x] Truth status separated from specification.
- [ ] Local Flutter format/analyze/test/build executed.
- [ ] SQL lint/migration validation executed.
- [ ] Supabase staging and RLS tests executed.
- [ ] Two-user Android/device integration baseline executed.
- [ ] CI and reproducible build established.

**P01 status: IN_PROGRESS (remote source audit documented; execution evidence unavailable).**
**Next:** P02 Architecture & Contracts: establish canonical domain/API/schema contracts and E2EE redesign before adding more feature UI.
