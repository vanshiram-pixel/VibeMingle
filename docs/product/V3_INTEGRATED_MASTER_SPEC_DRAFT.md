# VibeMingle Integrated V1 + V2 + V3 Master Specification — Draft

Product: VibeMingle — Connect Beyond Borders
Status: DRAFT / NOT APPROVED / NOT IMPLEMENTED
Scope: V1 foundation + all agreed V2 advanced features + V3 global platform capabilities form ONE final integrated product. No feature is silently removed. This document is design—not executable software.

## 0. Product and delivery rules
- Final surfaces: Flutter Android; Next.js user web; Next.js Admin Console; backend/API; database; realtime signaling/chat; LiveKit/WebRTC; AI; billing/economy; notifications; operations.
- Requirement lifecycle: DISCOVERED → SPECIFIED → REVIEWED → APPROVED → IMPLEMENTED → WIRED → TESTED → VERIFIED. A UI alone is not completion.
- Local-first workflow: local development → isolated development → staging → production. Synthetic test data only outside production.
- Every approved change has an ID, rationale, dependency/impact review, acceptance criteria and change history.
- Historic V1/V2/V3 scope must be reconciled against source discussions/docs before final approval. Unknown details are marked OPEN, never guessed.

## 1. Identity, authentication and onboarding (V1)
- Google-only Continue with Google; same action for registration/login. No email/password, phone OTP or Apple in baseline.
- Identity uses Google stable subject (sub), not email matching. Server validates issuer/audience/signature/expiry/nonce/state; secure redirect and PKCE/state.
- Session creation/refresh/revocation, logout, logout-all, device/session view, suspicious session controls and account deletion.
- First login: welcome → lawful age assurance → Terms/Privacy/Community Guidelines consent → unique username → display name/avatar → country/region/language → match preferences → privacy/safety choices → profile preview.
- Username normalization, reserved names, profanity/impersonation checks, availability, rate limit and change cooldown.
- Resume incomplete onboarding; persist consent/version; account states active/restricted/suspended/review/deletion-pending/deleted.
- Profile: public/private fields, avatar moderation, bio, badges, VIP, friend state, report/block. Never expose email, internal IDs, exact location or moderation notes.

## 2. Main user pages and route inventory
- Boot/splash, maintenance/update, welcome, Google login, age gate, consent/legal, onboarding steps, home/dashboard.
- Random match entry, preferences, queue/search status, candidate-ready/connecting, live call, call controls, in-call chat, translation, report, block, emergency exit, reconnect/quality, call ended/feedback/next.
- Friends, friend requests, social inbox, private messages/conversation, profile view, own profile/edit, privacy/safety, blocked list, sessions/devices, notifications, language/accessibility.
- VIP/plans, purchase/restore, coins/wallet/history, gift catalog/send/received, referral/invite/status, achievements/rewards.
- Safety/report status/appeal, support/FAQ/tickets, legal, account export/deletion, error/offline/permission-denied/empty/loading states.
- Admin: MFA login; dashboard; user search/detail; sanctions; reports/cases/evidence; appeals; live safety operations; policy/content; wallet/payment/refund/reconciliation; plans/entitlements/catalog/promotions/referrals; ads; CMS/legal/help; analytics; flags/rollouts; incidents/status; RBAC; audit; retention/deletion.

## 3. Matching engine (V1 core)
- User starts random match; queue is server-authoritative, cancellable, observable and idempotent.
- Discussed default: nearby/coarse-region matching; manual country/region or worldwide. Never reveal precise GPS/exact distance.
- Previously discussed gender preference: OFF = opposite gender; ON = all/random. This exact behavior is OPEN for explicit reconfirmation and legal/policy review; no gender inference from face/voice.
- Language, country, interests, connection quality, safety eligibility, wait fairness, repeat-pair suppression and capacity can affect compatibility.
- Eligibility checks: account active, age/jurisdiction allowed, no mutual block, not already in call, no restriction, rate limits, compatible preferences and capacity.
- Lifecycle: IDLE → PREFLIGHT → QUEUED → RESERVED → BOTH_READY → ROOM_CREATED → CONNECTING → LIVE → ENDING → COMPLETED; alternate cancel/timeout/reject/disconnect/failure.
- Atomic reservation, short expiry, both-side readiness, no duplicate room/match, stale ticket invalidation, fair queue, bounded starvation, safe preference-change requeue.
- 15-second normal skip lock, server timestamp authoritative. Report/block/emergency exit never locked. Failure skip behavior/cooldown scope OPEN.
- Queue telemetry: wait, cancel, match success, connection failures, coarse region and quality; minimize personal data.

## 4. Video, room and call engine
- LiveKit/WebRTC; server-issued short-lived scoped room tokens; authorization on every join; no client-selected arbitrary room/user.
- Camera/mic permission flows, denial/settings retry, mute, camera on/off/switch, speaker/headphone routing, quality indicator and call timer.
- Adaptive bitrate/resolution, ICE/TURN, reconnect/backoff, network switch, app background/foreground, degraded connection, remote leave, room recovery and cleanup.
- States: requesting/connecting/live/reconnecting/degraded/remote-left/ended/failed. End call idempotently and release room, queue and billing resources.
- No recording by default. Any recording/transcription requires informed explicit consent, revocation and legal/platform approval; no hidden capture.
- OPEN: max call duration, supported devices/OS, region routing, private-room roles.

## 5. In-call actions and safety
- Video surfaces/local preview, mute, camera, switch camera, speaker, chat, translation, next, report, block, emergency exit.
- 15-sec skip lock only affects normal next; safety actions remain available and reachable.
- Report: reason/category, optional text/user-submitted evidence, case ID, confirmation; no automatic private-video capture.
- Block: immediate server effect; prevent future matching/messages/requests; cancel pending relationships; unblock from list; no alert to blocked party.
- Report abuse/false reports, rate limits, retaliation safeguards, safety education; feedback is optional.

## 6. Chat, friends and consent-based private calls
- In-call text, system notices, original/translated display, delivery/failure, spam/profanity rate controls; links/media are not assumed enabled.
- Friend request send/accept/reject/cancel/expire; duplicate prevention; remove friend; block cancels relationship and requests.
- Friend list, privacy-aware presence/last-seen, profile, invite; no exact location.
- 1:1 text inbox, conversation list, unread, push, mute/archive/delete-view, report/block, stranger message request acceptance and anti-harassment controls.
- Server checks both participants for every conversation operation. Retention and E2E encryption model OPEN.
- Private audio/video request: explicit scope, accept/reject/ignore/withdraw/expiry; spam limits; recipient consent; both parties camera/mic permission; rejection stops repeated requests; safety actions always available.
- OPEN: private-call price/access (friend-only/free/paid), duration and billing policy; payment never overrides consent.

## 7. AI translation
- Optional voice translation/subtitles, OFF by default; user selects language/mode; original audio fallback and instant stop.
- Clearly label translated/synthetic output; consent/disclosure; no default audio retention/training; minimize logs.
- Language fallback, latency, outage, quota, per-user/global budget, provider/model flags and kill switch.
- Prompt injection via transcripts, hateful content, misinterpretation, impersonation and cost abuse considered; AI output is not moderation truth.
- OPEN: provider, supported languages, processing region, retention, voice-cloning prohibition.

## 8. Trust, safety, moderation and appeals
- Guidelines, prohibited behavior, age assurance, adult/minor separation, region rules and escalation.
- Report categories: harassment, sexual/nudity, minors, hate, threats, spam/scam, impersonation, privacy, other; severity, triage, case, evidence policy, sanctions, appeal.
- Sanctions: warning, restriction, temporary suspension, permanent ban; reason codes, progressive/severity rules, audit and appeal.
- Automated risk signals are aids, not unquestionable decisions; false-positive review and transparency.
- Moderator least privilege; evidence access logged/time-limited/redacted; no covert surveillance.
- Child safety escalation, lawful requests, legal hold/deletion exception and incident handling need specialist/legal review.
- OPEN: moderation coverage/SLA, evidence retention, appeal window, jurisdiction policy.

## 9. Economy, subscriptions, gifts and rewards
- VIP/plan catalog, localized price, purchase, restore, renewal/expiry/cancel, grace, refund/revocation and entitlement.
- Android digital goods via Play Billing; web provider only where allowed; server validates receipts; client success is not authority.
- Coins/wallet, catalog, send/receive gifts, history, refund/chargeback, reconciliation and fraud queue.
- Append-only ledger, atomic transfers, integer minor units, idempotency, unique provider transaction, no negative balance, duplicate webhook cannot double-credit.
- Referral code/link, attribution window, eligibility, anti-self-referral, pending/confirmed/reversed reward, fraud review.
- Achievements/streaks/rewards, opt-out and anti-manipulative design; rules versioned/server-authoritative.
- OPEN: coin value/prices, VIP benefits, gift rules, taxes, refunds, regional availability; withdrawal not assumed.

## 10. Ads, notifications and support
- Web AdSense / Android AdMob only in approved placements, consent/age/jurisdiction review; no ads over/in active call; no accidental overlays; frequency caps; VIP ad-free if defined.
- Ads/promotions distinct; admin placement/config/kill switch; no personalized ads without lawful consent.
- FCM + in-app inbox: friend/message/gift/account/safety/subscription/announcement; preference categories, quiet hours, token rotation, retries/dedup; sensitive content absent from lock screen by default.
- Support/FAQ/search/ticket/contact/attachment safety/status/reply/escalation; support role cannot access moderator/admin privileges.

## 11. Settings, privacy and lifecycle
- Profile discoverability, visibility, presence, message requests, displayed country/language, permissions; blocked users; notification/accessibility/translation; sessions/devices; logout/all.
- Data export, account deletion request, reauth, confirmation, progress/completion, legal hold and retention exceptions documented.
- Data minimization, purpose limitation, consent versions, retention/deletion schedule, privacy rights and audit.

## 12. Backend logical engines
1 Identity/Auth/Session; 2 Profile/Onboarding; 3 Preference/Eligibility; 4 Queue/Match/Reservation; 5 Room/LiveKit Token/Call Lifecycle; 6 Signaling/Presence; 7 Chat/Messaging; 8 Friend/Social Graph; 9 Private Request/Consent; 10 AI Translation; 11 Trust/Risk; 12 Reports/Cases/Appeals/Enforcement; 13 Wallet/Ledger/Coins/Gifts; 14 Billing/Entitlement/Webhook/Reconciliation; 15 Referral/Reward/Achievement; 16 Ads/Promotion/Consent; 17 Notifications; 18 Support/Tickets; 19 CMS/Legal/Policy; 20 Admin/RBAC/Audit; 21 Analytics/Experiment/Telemetry; 22 Flags/Configuration; 23 Search/Discovery; 24 Export/Deletion/Retention; 25 Global Routing/Capacity; 26 Observability/Incident/DR.
- Each engine requires contract, input/output, auth, idempotency, error/retry, metrics, tests and ownership. Start modular, not premature microservices.

## 13. Logical data entities
- users, auth_identities, sessions/devices, profiles/privacy, onboarding, consents, age_assurance.
- preferences, queue_tickets, reservations, matches, rooms, participants, call_events, quality_metrics.
- messages, conversations/members, friend_requests/friendships, presence, private_call_requests, consent_events.
- reports/evidence_metadata, moderation_cases, sanctions, appeals, policy_versions.
- wallets, ledger_accounts/entries, coin_products, gifts/transfers, purchases, subscriptions, entitlements, payment_events, refunds, reconciliation_runs.
- referral_codes/attributions, reward_events, achievements, notification_preferences/tokens/notifications, support_tickets/messages.
- feature_flags, experiments, app_config, CMS/legal docs, admin_users/roles/permissions/sessions/audit_logs, export/deletion/retention jobs, region_capacity/health/incidents.
- UUID/opaque IDs, FKs/unique constraints/indexes, immutable ledger/audit, explicit retention, no secrets/unneeded PII in logs.

## 14. API/events/integrations
- Versioned typed API, consistent error envelope, trace ID, validation, safe pagination, request limits, rate limits and abuse throttles.
- Realtime event schema/version/correlation/idempotency; retries/dead-letter; duplicate/out-of-order event handling.
- Webhook signature/time/replay validation, unique event ID, idempotency, retry and reconciliation.
- Google OAuth ↔ identity ↔ profile; preferences ↔ eligibility ↔ queue ↔ match ↔ LiveKit; chat/social ↔ privacy/block ↔ notifications; consent ↔ AI; safety case ↔ moderation ↔ sanctions/appeal ↔ eligibility; billing ↔ ledger ↔ entitlements; gifts/referrals ↔ rewards/ledger; ads ↔ consent/age/entitlement; admin ↔ RBAC/MFA/audit; deletion/export ↔ every data module; flags ↔ rollout/rollback; monitoring ↔ SLO/incident/runbook.

## 15. Security and red-team requirements
- Threats: OAuth takeover/replay, session theft, IDOR, RLS bypass, room-token theft, match manipulation, harassment/child safety, admin compromise, payment replay, double spend, webhook spoof/replay, AI prompt injection, data exfiltration, supply chain, DDoS and insider abuse.
- Least privilege, admin MFA, step-up for sensitive actions, scoped short-lived tokens, rotation, secure secrets manager; no service-role key in clients.
- TLS, CSP/headers, CSRF, validation, XSS/SQLi, SSRF, upload scanning/size limits/metadata stripping, dependency pinning/SBOM, code scanning, signed builds/provenance.
- RLS tests on every sensitive table plus negative cross-user authorization; RLS defense-in-depth, not substitute for server authorization.
- PII minimization, encryption, retention, access review, audit, privacy threat model and incident/vulnerability disclosure plan.
- No claim of 100% security; measurable controls and test evidence.

## 16. V3 global platform and operations
- Region-aware routing/capacity/failover, data residency/legal review, queue fairness, global localization.
- Flags, canary, staged rollout, rollback, maintenance/kill switch; mobile compatibility/version gate.
- SLOs for availability, queue wait, call connect, latency, crash-free sessions, safety response and payment reconciliation (targets OPEN).
- Logs/metrics/traces, crash reporting, LiveKit quality, DB/API health, AI spend, payment and abuse alerts; incident/on-call/postmortem/status.
- Backups, PITR and restore drills; RPO/RTO OPEN; budget alerts/quotas for video, AI, storage, notifications and DB.
- Environments local/dev/staging/prod isolated; CI lint/type/unit/integration/E2E/security/migration/build/release/rollback.

## 17. Proposed repository layout (target, not current code)
apps/mobile (Flutter Android); apps/web (Next.js); apps/admin (Next.js); services/api; services/realtime; services/workers; packages/contracts; packages/design-system; packages/config; supabase/migrations, seed, functions; docs/product, architecture, api, data, security, operations, testing, decisions; infra/local, ci, deploy; scripts; .github/workflows.
- ADR required for Flutter structure, Supabase Edge vs dedicated API, modular boundaries, realtime transport and payment providers.

## 18. Mandatory page-by-page spec template
- Screen ID, platform, route, access prerequisite, user goal, entry/exit navigation.
- Layout/components/responsive/accessibility; every button/control ID, enabled condition, handler, API/local operation, loading/success/error/retry/confirmation.
- Data query/mutation, optimistic behavior, state machine, empty/offline/restricted states.
- Permission/server auth/RLS/privacy classification; validation/rate limits/idempotency/abuse protection.
- Dependencies/events/cleanup, unit/widget/E2E/accessibility/security tests, acceptance criteria and lifecycle status.
- No inert button; disabled reason; duplicate submit prevention; safe retry; back/deep-link/background/resume/network switch/app restart behavior.

## 19. Verification gates
- Unit: eligibility, scoring, state transitions, ledger, consent, policy.
- Integration: OAuth, DB/RLS, API, LiveKit tokens, messaging, webhook, notifications, deletion/export.
- E2E: onboarding, queue→call→end, skip lock, report/block, friends/chat, purchase/restore, appeal, deletion.
- Security: IDOR, escalation, RLS cross-user, token/webhook replay, unauthorized room join, rate bypass, upload, XSS/CSRF/SSRF, secrets.
- Reliability: reconnect, app lifecycle, network switch, restart, duplicate events, partial failure, region failover, restore drills.
- Accessibility/localization/performance/device/low-bandwidth/permission denied; payment sandbox/reconciliation; AI budget/kill; moderation simulations.
- Release blocker: critical/high unresolved issue, core E2E fail, ledger mismatch, unsafe age/moderation, broken deletion, no rollback/restore evidence.

## 20. OPEN DECISIONS (must not be silently guessed)
Age assurance/jurisdictions; gender preference exact behavior; nearby coarse-region method; skip-lock anchor/scope; max call duration/devices; private-call access/pricing; chat encryption/retention; AI provider/languages/region/retention; coin/VIP/gift/refund/tax; ad consent/age/ad-free; moderation SLA/evidence/appeals; launch regions/languages/data residency; SLO/RPO/RTO/capacity; analytics/consent; service/API boundaries; legal entity/terms/privacy/child safety.

## 21. Final integrated lock acceptance
- Reconcile all historic V1/V2/V3 discussion/docs feature-by-feature with traceability; no omission.
- Every requirement has ID, priority, dependencies, owner, acceptance criteria and status.
- All screens/routes/button/action IDs, engines, APIs, schema/RLS, events, integration and failure paths specified.
- Security/privacy/safety/red-team controls assigned and evidence planned; open decisions resolved or explicitly risk-accepted.
- Local setup, environments, test matrix, release/rollback/backup plans complete; product owner approval recorded.
- Post-lock changes require change log and impact review.

## Current truthful status
This is a consolidated, broad master draft based on known product decisions and recovered prior context. It is NOT yet a complete transcript-level reconciliation of every past chat, NOT product-owner approved, NOT implemented, NOT wired, NOT tested, and NOT verified. The GitHub repository remains a starter shell until code is added.