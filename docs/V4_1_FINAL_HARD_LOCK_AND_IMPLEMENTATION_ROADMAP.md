# VibeMingle V4.1 — FINAL HARD LOCK & IMPLEMENTATION ROADMAP

**Status:** PRODUCT SCOPE HARD-LOCKED (V4.1)  
**Branch:** feat/typing-presence  
**Supersedes:** V4 scope freeze as the current implementation target; preserves V1/V2/V3/V4 decisions and all post-V4 review additions.

## 1. Final decision

VibeMingle V4.1 is the sole product scope for implementation, integration, QA, deployment preparation, and launch readiness. No feature expansion or scope change is permitted beyond this document and its linked canonical specifications. Existing approved V4 features and post-V4 review additions are consolidated—not discarded.

This is a **scope lock**, not a claim that software is already implemented, integrated, tested, deployed, or launch-approved.

## 2. Canonical specification set (read together)

1. [V4 final hard locks](V4_FINAL_HARD_LOCKS.md)
2. [Final master product blueprint](FINAL_MASTER_PRODUCT_BLUEPRINT.md)
3. [Updated screen-by-screen, page-by-page, button-by-button blueprint](V4_FINAL_UPDATED_SCREEN_BY_SCREEN_BUTTON_BLUEPRINT.md)
4. [Advanced add-ons: translation, chat, privacy/security](V4_ADVANCED_ADDONS_TRANSLATION_CHAT_SECURITY.md)
5. [V4.2 advanced add-ons / roadmap integration](MASTER_ROADMAP.md)
6. [25-phase development plan](V4_25_PHASE_FINAL_DEVELOPMENT_MASTER_PLAN.md)
7. [Repository audit and V1–V4 reconciliation](V1_V2_V3_V4_RECONCILIATION_AND_REPOSITORY_AUDIT.md)
8. [Instant stranger matching](instant-stranger-matching.md)
9. [Unified connections/social system](CONNECTIONS_UNIFIED_SOCIAL_V4.md)
10. [Stranger match/friend flow](STRANGER_MATCH_FRIEND_FLOW.md)

The screen-by-screen blueprint is the UI behavior reference; the advanced add-on and hard-lock documents are authoritative for cross-cutting security/privacy/product constraints. Conflicts must be resolved in favor of the stricter security rule and recorded before implementation—never silently changed.

## 3. V4.1 included scope

- Android app, responsive website/PWA, and Admin/Ops console.
- Google-only sign-in; onboarding, age eligibility, consent, profile, privacy and account lifecycle.
- One unified Connections hub: friends, requests, followers/fans, following, discover; one canonical chat per relationship/thread.
- Discover, presence, instant random matching, Next/Switch, manual stranger search with filters and preview; server-authoritative fair queue and atomic pairing.
- Stranger video, private audio/video calls with request → accept → secure room/token → join.
- Full advanced chat: E2EE, text, voice notes, media/file/video attachments, replies, reactions, controlled edit/delete/forward, typing, delivery/read receipts, pin/mute/archive/search, disappearing messages, safe links, attachment scanning, call requests.
- Voice translation across supported stranger/private audio/video and relevant accepted call flows; language selection/detection, translated/original captions/audio, consent, controls and fallback.
- Notifications, deep links, profile/media viewer, wallet/VIP/coins/gifts/payments, rewards/referrals, CMS/campaigns, support/help.
- Privacy-preserving AI safety, reports, block enforcement, selected evidence and appeal; no universal plaintext access or covert recording.
- Admin/Ops: live health/telemetry, match/call/chat/translation diagnostics, moderation case workflows, scoped evidence vault, RBAC/audit, remote config/feature flags, staged rollout, emergency stop and rollback.
- Web/PWA functional parity within supported browser/device capabilities; explicit graceful degradation where native functionality is unavailable.
- Reliability, accessibility, observability, security, abuse resistance, performance, compliance, backups/recovery, incident response and launch operations.

## 4. Non-negotiable security/product invariants

- Block overrides discover, follow, chat, call and matching paths.
- Follow does not imply friendship, chat permission or call consent.
- Friendship does not imply call consent; recipient must accept a private call request.
- Server authoritative state, authorization, pairing, payment ledger, consent and report/block actions.
- One active match/session per user; idempotent actions, stale queue cleanup, presence TTL and cooldown.
- Next cooldown: 15 seconds; End/Report/Block/Mute/Camera Off remain immediate.
- Matching latency figures are targets under compatible-peer/network conditions, never guarantees.
- No silent filter broadening; tell user if selected filters cannot be honored.
- No covert camera/mic use or hidden recording.
- E2EE means Admin has no universal decryption key/backdoor. Only selected/report-authorized evidence may be exported, encrypted, restricted, audited and retention-limited.
- No blanket chat plaintext surveillance or universal chat ZIP export.
- IP geolocation is approximate; no precise home address exposure. GPS is not visible to strangers and only collected with justified permission/consent.
- AI safety is context-aware, not keyword-only automatic punishment; human review, appeal and false-positive handling.
- **Per user scope instruction:** sexual exploitation/grooming indicators are excluded from the general AI safety monitoring/detection/alert category. Do not create a dedicated detector/monitor/alert for that topic. This exclusion does not remove other safety categories.
- Admin emergency controls cannot disable authentication, encryption, consent, report/block or immediate safety exits.
- Security is defense-in-depth; never promise zero hacks/bugs.

## 5. Implementation truth labels

Use these labels in all progress reports and issue/PR descriptions:
- **SPECIFIED** — behavior/contracts documented.
- **IN_PROGRESS** — work started, incomplete.
- **IMPLEMENTED** — code exists.
- **INTEGRATED** — connected end-to-end across required components.
- **VERIFIED** — evidence from relevant automated/manual/device/security tests.
- **RELEASED** — approved deployment/release completed.

Documentation, mock UI, schema proposals, or a Git commit alone must not be described as integrated/verified/released.

## 6. Execution sequence (scope fixed; work proceeds forward)

### Track 0 — Baseline and repository truth
- Inventory repository, framework, packages, apps, existing screens, backend, migrations, tests, CI, secrets/config boundaries.
- Map current code to V4.1 requirements; identify gaps and risks.
- Record baseline build/test status and exact commands/results where executable.
- No destructive reset or overwriting working code without preserving/reviewing it.

### Track 1 — Architecture/contracts/foundation
- Define app/web/admin boundaries, module ownership, API conventions, errors, auth/session, environment strategy, observability.
- Define typed API request/response schemas, validation, pagination, idempotency, versioning.
- CI quality gates, lint, formatting, unit/integration/security checks.
- Dev/staging/prod environment separation; secret handling and migration discipline.

### Track 2 — Identity and account lifecycle
- Google OAuth state/nonce/PKCE, server token verification, secure session refresh/revocation.
- Onboarding, age eligibility, terms/privacy and feature-specific consent; profile/media.
- Account recovery/deletion/export and session/device management.
- Enforce authorization server-side.

### Track 3 — Social/privacy/discovery
- Profiles, visibility, search/discovery, follow/friend requests, accept/decline/cancel/remove.
- Unified connections lists and canonical thread identity.
- Block/report/mute enforcement across all entry points.
- Presence and notification/deep-link behavior.

### Track 4 — Chat and media
- E2EE key lifecycle, device keys, key verification/recovery model, ciphertext persistence.
- Realtime delivery, receipts, typing, retries, deduplication and offline sync.
- Attachment upload authorization, size/type checks, scanning, signed URLs, retention.
- Replies/reactions/edit/delete/forward/pin/archive/mute/search/disappearing messages.
- Selected report evidence workflow without compromising universal E2EE.

### Track 5 — Matchmaking and stranger video
- Server-authoritative queue, filter/preview contracts, atomic pairing, cancellation, Next cooldown, fairness, cleanup and reconnect.
- Session state machine and one-active-session invariant.
- WebRTC signaling, STUN/TURN credential service, network/device permissions, reconnection and safe exits.
- Report/block/end and post-match friendship/follow/chat transitions.

### Track 6 — Private calls and translation
- Call request/accept/reject/cancel/timeout, secure room/token and participant authorization.
- Audio/video device handling, reconnect, call conflict and diagnostics.
- Translation service adapter, consent, language detection, original/translated caption/audio, latency/error fallback, service availability and admin rollout.
- No translation provider secrets in clients.

### Track 7 — Admin/Ops and commercial modules
- Admin RBAC, least privilege, audit trails and scoped evidence access.
- Health dashboards, alerts, incident workflow, safe remote config and rollback.
- Moderation/report queue, appeals, support, CMS, campaigns.
- Payments server verification/webhooks, idempotent ledger, refunds/receipts, VIP/coins/gifts.
- Rewards/referrals anti-abuse and server-side eligibility.

### Track 8 — Website/PWA and parity
- Responsive routes, auth/onboarding, profile/social/chat/calls/matching and other included modules.
- Browser support matrix; graceful fallbacks for unsupported media/permissions.
- Deep links, install/offline shell, accessibility and responsive QA.

### Track 9 — Full verification
- Unit, API contract, integration, realtime, end-to-end, browser, Android/device and regression tests.
- Security review: auth/authorization, IDOR, rate limits, queue abuse, block evasion, WebRTC token leakage, attachment abuse, XSS/CSRF, secret exposure, payment replay, admin privilege abuse, evidence access and data retention.
- Load/performance, reconnect/network loss, duplicate events, race conditions, migrations/rollback, backup/restore, accessibility and privacy checks.
- Resolve critical/high issues before beta; maintain reproducible evidence and release notes.

### Track 10 — Beta, deployment and launch readiness
- Internal QA → closed beta → staged rollout; monitor error rates, crash-free sessions, match success, call quality, chat delivery, translation health, abuse reports and support load.
- Release checklist, rollback rehearsal, incident contacts/runbooks, data migration/backup, store/web assets, privacy/terms, provider readiness and cost limits.
- Production deployment and public launch are **owner approval gates**. Notify user and obtain explicit approval before production deployment, public launch, store release, or PR merge.

## 7. Release gates (must pass in order)

1. **Scope gate:** this V4.1 lock and linked canonical docs.
2. **Code gate:** required modules implemented; no placeholders represented as complete.
3. **Integration gate:** app/web/backend/admin/providers connected with contract evidence.
4. **Quality gate:** CI green and documented manual/device tests.
5. **Security/privacy gate:** threat review, authorization, E2EE/evidence validation, consent, block/report tests, secret audit.
6. **Operational gate:** monitoring, alerts, backup/restore, incident and rollback drills.
7. **Beta gate:** acceptance criteria, feedback triage, critical/high issues resolved.
8. **Launch gate:** user approval required; deployment plan and rollback ready.

## 8. Definition of done for every screen/function/button

For every item in the screen-by-screen blueprint, record:
- Stable screen/action ID and user-visible label.
- Route/navigation destination and back behavior.
- Preconditions, enabled/disabled/loading states.
- Frontend handler and validation.
- API method/path + typed request/response + error codes.
- Backend authorization and business logic.
- DB tables/entities, indexes, constraints and transaction boundaries.
- Realtime event/topic, payload contract and idempotency (if applicable).
- Success state/navigation and retry/timeout/offline/conflict behavior.
- Privacy/security controls and telemetry (without sensitive payload leakage).
- Admin visibility/control where justified.
- Unit, integration, E2E, accessibility and abuse tests.
- Evidence and truth status (SPECIFIED/IN_PROGRESS/IMPLEMENTED/INTEGRATED/VERIFIED/RELEASED).

## 9. Change control

No scope additions beyond V4.1. Fixes, implementation details, reliability improvements and security corrections are allowed when they preserve scope and invariants. Any proposed scope change must be explicitly presented to the owner as a separate future version; it must not silently enter V4.1.

## 10. Immediate next work

1. Audit current GitHub repository contents and actual implementation baseline.
2. Create a V4.1 traceability matrix (screen/action → API → DB → event → tests → status).
3. Build exact API contracts and database schema/migrations.
4. Implement modules in dependency order, commit continuously, and record honest verification evidence.
5. Update this roadmap as work advances; no production deployment or public launch without owner approval.

**Final scope statement:** VibeMingle V4.1 is hard-locked as the complete implementation target. The linked specs together define the approved scope. Development now proceeds to implementation, integration, QA, deployment preparation and launch readiness—without adding features outside V4.1.
