# VibeMingle — Advanced Product Quality, Integration & Red-Team Requirements
**Status:** REQUIRED ENGINEERING BASELINE — NOT A RELEASE CERTIFICATE  
**Branch:** feat/typing-presence  
**Decision:** No MVP scope. Full V1+V2+V3 feature preservation under V4 unified architecture. No production launch without explicit owner approval.

## 1. Product commitment
VibeMingle is intended as a complete, advanced Android + Web/PWA + Admin/Ops product. This document converts the owner's explicit requirements into engineering acceptance criteria. “Complete” means every included feature has a real frontend, backend, data, authorization, realtime behavior, error handling, observability, tests, and documented operational ownership—not merely a screen, mock, schema, or TODO.

## 2. Merge and canonicalization rules
- Inventory all V1, V2, V3, and V4 requirements, source documents, code, routes, screens, APIs, repositories, state machines, database objects, and event names.
- Preserve every unique feature. Duplicate implementations must be compared for behavior, security, data compatibility, test coverage, and migration impact before selecting a canonical owner.
- Never delete a duplicate solely because names look similar. Establish equivalence, migrate callers/data, add compatibility adapters if needed, test, then retire the duplicate.
- Maintain a feature traceability register: Feature ID, historical origin/version, canonical module, UI entry points, API/service, DB/RLS, events, tests, status, evidence, and known gap.
- Enforce one canonical source of truth for identity, relationships, chat threads, calls, match sessions, wallet/ledger, moderation cases, notifications, and user safety state.
- No silent feature removal, scope reduction, or MVP substitution.

## 3. End-to-end wiring and navigation
Every screen, button, menu, action, route, deep link, redirect, modal, notification, and admin action must be traced end-to-end:
1. Visible/hidden/disabled conditions and permission checks.
2. User action and client validation/loading state.
3. Authenticated API/service call with request ID/idempotency where applicable.
4. Server validation, authorization, rate limiting, domain logic, and transaction boundary.
5. Database mutation/read with constraints and RLS/service-role boundaries.
6. Realtime event/outbox delivery where required; client subscription and state reconciliation.
7. Success state, destination/redirect/deep link, analytics/audit event.
8. Failure state, human-readable error, retry/backoff, rollback/compensation, and recovery.
9. Unit, widget, integration, contract, RLS, and E2E test proving the path.

No dead buttons, fake success, unhandled routes, redirect loops, stale navigation state, duplicate subscriptions, lost events, or frontend-only permissions.

## 4. Real-time correctness
- Use server-authoritative state and versioned event contracts; clients must tolerate duplicate, delayed, reordered, and missed events.
- Idempotent consumers, reconnect/resubscribe, snapshot reconciliation, sequence/version checks, TTL cleanup, bounded retries, dead-letter/alerting where appropriate.
- Presence, typing, chat delivery/read receipts, friend/request changes, notifications, match queue/session state, call signaling/quality, moderation alerts, and operational health should update in real time when product semantics require it.
- Realtime must not bypass authorization or expose private payloads to unauthorized subscribers.
- Document freshness/SLO targets and test disconnect/reconnect, multi-device, offline, and race conditions.

## 5. Video/audio calling — critical quality gate
Implement and validate a robust WebRTC calling stack (provider may be LiveKit or an approved equivalent; decision must be documented):
- Private call request → recipient consent/accept → room/token issuance → join; no automatic call consent from friendship.
- Stranger video pairing/session consent and safety controls; separate lifecycle from private calls.
- Permission preflight for camera/microphone; clear denied/blocked states and OS settings guidance.
- Camera on/off, microphone mute/unmute, front/back camera switch, device selection where supported, speaker/audio route, connection quality indicators, safe leave/end, report/block, call timer, participant state.
- Signaling lifecycle, ICE gathering, STUN/TURN, relay fallback, secure short-lived room credentials, reconnect/rejoin policy, network changes (Wi-Fi/mobile), background/foreground, app interruption, device rotation, permission revocation, remote participant drop, server/provider outage, token expiry, and cleanup.
- Distinguish reconnecting vs failed vs ended; never show false “connected” or silently leave orphan rooms.
- No old stranger session rejoin or unintended direct call; private calls require explicit recipient acceptance.
- Call quality telemetry: join latency, time-to-first-media, reconnects, ICE candidate type (privacy-safe), packet loss/jitter/RTT, bitrate, freeze/audio gaps, end reason, client/app version, region/provider health.
- Red-team: unauthorized room join, guessed IDs, token reuse/expiry, participant impersonation, signaling injection, replay, cross-room leakage, call spam, consent bypass, recording/screenshot disclosure policy, TURN credential exposure, PII in logs.
- Test real Android devices and supported browsers across network profiles; automated tests plus manual matrix. Do not claim calling is verified until actual provider/config/device tests exist.

## 6. Admin/Ops without-code operations
Admin is an operational control plane, not a decorative dashboard:
- RBAC/least privilege, separate privileged roles, MFA/step-up for sensitive actions, audited actions, approval/dual-control for high-risk changes, session expiry, IP/device risk controls where appropriate.
- Real-time system health and incident center: API errors, crashes, failed jobs, queue backlog, realtime disconnects, call/match failures, database/provider health, abuse/security alerts.
- Error reports include correlation ID, release/build, environment, sanitized stack/trace, route/module, timestamp, impact, frequency, and reproducible context. Scrub secrets, tokens, message bodies, media, and unnecessary PII.
- Live configuration/feature flags, staged rollout, kill switches, rollback to last known safe configuration; validate config schema and environment, audit every change, cache invalidation and propagation confirmation.
- User moderation, reports/appeals, account controls, content/CMS, notices, campaigns, feature settings, matching parameters, call provider status, payment reconciliation, analytics, support tools, audit logs, and release visibility.
- Admin cannot change arbitrary server code, database schema, secrets, or security invariants through unsafe UI. Such operations require controlled engineering/deployment.
- Incident response: alert thresholds, ownership, severity, runbooks, acknowledge/escalate, incident timeline, remediation and postmortem.

## 7. Security and red-team program
Threat-model and test at minimum:
- Authentication/session: Google OAuth state/nonce, PKCE where applicable, token storage, refresh/revoke, account takeover, session fixation, logout across devices.
- Authorization: object-level IDOR/BOLA, role escalation, tenant/room/thread boundary, admin privilege separation.
- API: schema validation, injection, mass assignment, SSRF, CORS, CSRF where applicable, request size limits, abuse/rate limits, replay/idempotency.
- Database/storage: RLS for every exposed table, private buckets, signed URL expiry, least-privilege service role, backup/restore, migrations, secrets management.
- Realtime: channel authorization, subscription filters, event payload minimization, forged events, replay and leakage.
- WebRTC: room/token authorization, TURN secret protection, signaling security, participant identity and consent.
- Business logic: match/call/chat spam, friend/follow manipulation, gift/payment double-spend, wallet ledger integrity, referral/reward abuse, moderation bypass.
- Client: deep-link validation, unsafe WebView, secure local storage, dependency/supply-chain scanning, release signing and integrity.
- Privacy: data minimization, retention/deletion/export policy, consent, age eligibility, AI/transcription/translation opt-in, safety reporting/evidence access, privacy-safe telemetry.
- Use OWASP ASVS/MASVS/API Security Top 10 as applicable; SAST, dependency/license scanning, secret scanning, DAST, RLS tests, abuse cases, and independent review before launch.
- Red-team findings must have severity, evidence, owner, fix, retest, and closure; no unresolved critical/high findings at launch (unless documented exception explicitly accepted by owner and legal/security lead).

## 8. Reliability, performance, and completeness
- Define SLOs for API latency/error rate, realtime delivery, matching latency/success, call join/quality, crash-free sessions, availability, and recovery.
- Load/stress/soak tests, queue fairness, multi-region behavior, graceful degradation, circuit breakers, backpressure, capacity alarms, backups and restore drills.
- Accessibility, localization, responsive web parity, empty/loading/error states, offline/reconnect states, and analytics privacy.
- CI: format/lint, unit/widget tests, contract tests, integration tests, migration/RLS checks, build artifacts, security scans, and gated release workflows.
- No hidden TODOs, stubs, mock providers, fake endpoints, placeholder screens, partial engines, or disabled features presented as completed. Track explicitly if unavoidable and block release.

## 9. Required audit artifacts
1. V1/V2/V3/V4 traceability and preservation matrix.
2. Duplicate inventory + canonical merge decisions + migration/compatibility plan.
3. Full screen/page/subscreen inventory Android, Web/PWA, Admin/Ops.
4. Button/action/route/deep-link inventory with preconditions, service, state, error, redirect and test.
5. API inventory and frontend↔backend wiring matrix.
6. Database schema/index/constraint/RLS/storage audit.
7. Realtime event catalog and subscription/authorization matrix.
8. Video/audio calling architecture, state machines, failure matrix and device/browser test report.
9. Admin capabilities/RBAC/operational runbooks.
10. Threat model, red-team cases, vulnerability register and retest evidence.
11. CI/test coverage, build/device evidence, performance/load results.
12. Release checklist, rollback plan, incident response and explicit owner sign-off.

## 10. Honest status definitions
- SPECIFIED: requirements documented.
- DESIGNED: architecture/contracts approved.
- IMPLEMENTED: code exists; not necessarily integrated.
- INTEGRATED: end-to-end wiring exists.
- VERIFIED: tests/device/security evidence passed.
- RELEASED: deployed/released with approval.
A markdown document, UI, migration file, or mock alone never qualifies as implemented/integrated/verified.

## 11. Release gates
- No MVP-only release accepted as completion.
- No launch while critical/high security issues remain unresolved.
- No production deployment, public launch, store submission, or PR merge without owner notification/approval.
- Owner's autonomous development authorization covers routine coding, testing attempts, debugging, documentation, and commits; it does not waive release/security gates or justify claiming tests unavailable in this environment.
