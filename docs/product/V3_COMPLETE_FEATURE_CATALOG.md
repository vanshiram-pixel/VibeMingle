# VibeMingle — V3 Complete Integrated Feature Catalog

**Status:** Working catalog baseline (not implementation evidence)  
**Scope reference:** V3-FINAL-SCOPE-LOCK-01  
**Product:** VibeMingle — Connect Beyond Borders

> V1 foundation + V2 advanced + V3 global/platform capabilities are one integrated product. This catalog organizes requirements; it does not claim code, integrations, legal approval, or tests are complete. Every item must eventually have an owner, requirement ID, UI/API/schema mapping, security controls, acceptance criteria, and tests.

## 0. Global product invariants

- Adults only (18+); jurisdiction-aware age assurance and eligibility gate. A checkbox alone is not automatically sufficient.
- Google OAuth only; provider `sub` is the immutable identity key. Never auto-link accounts by email.
- No default call recording. Recording, if ever introduced, requires a separately approved product/legal design and explicit informed consent.
- Report, block, emergency exit, and safety controls are never subject to skip cooldowns or monetization gates.
- Match, call, wallet, entitlement, reward, and payment outcomes are server-authoritative.
- No client-held service secrets; enforce authorization server-side and with database RLS.
- Translation and other AI features are opt-in, disclosed, budget-limited, and fall back safely.
- No minors, sexual exploitation, non-consensual intimate content, or policy-prohibited content.
- Ads never interrupt an active live call; consent and platform policies apply.
- Account deletion/export, retention limits, privacy choices, appeals, auditability, and incident response are product requirements.
- No absolute claim of 100% security, moderation accuracy, or availability.

## 1. Apps, surfaces, and navigation

### 1.1 Flutter Android app

1. Splash / app bootstrap — config, maintenance state, update compatibility, crash-safe initialization.
2. Welcome — product explanation, 18+ eligibility, Terms/Privacy links.
3. Google sign-in — OAuth start/callback, cancellation, retry, invalid-token and disabled-account states.
4. Age assurance — age gate, verification outcome, denied/underage flow, jurisdiction restrictions.
5. Consent & privacy setup — camera/mic rationale, AI translation consent, discovery/location visibility, notifications.
6. Home — Match CTA, mode summary, balance/VIP, safety entry, status banners.
7. Discover / match preferences — language, interests, region/country, matching mode, privacy-aware controls.
8. Match queue — searching, estimated/unknown wait, cancel, network retry, queue timeout, no-match state.
9. Pre-call connection — peer availability, permission check, device/network check, connecting/retry/cancel.
10. Live call — remote/local video, mute, camera toggle, camera switch, speaker, connection quality, timer, leave.
11. Call safety sheet — report, block, emergency exit, reason selection, confirmation and immediate disconnect.
12. Call translation — source/target languages, subtitles, translated voice toggle, original audio, consent/status/cost guard.
13. Post-call — end status, optional feedback, report shortcut, safe next-match, ad eligibility, no forced ad.
14. Friends — list, online/away/offline privacy state, search, remove friend, block/report.
15. Friend requests — incoming/outgoing, accept/decline/cancel, rate limits and expiry.
16. Messages / inbox — conversation list, unread state, delivery/read policy, mute/archive/block/report.
17. Conversation — text messages, safe link policy, send failure/retry, abuse reporting, retention controls.
18. Private call request — request/accept/reject/ignore/withdraw/expiry; mutual consent and eligibility.
19. Private call room — invitation state, permissions, safety controls, end-call and reconnect.
20. Profile — avatar, display name, bio, languages/interests, privacy, verification badges only if earned.
21. Profile edit — validation, upload moderation, size/type limits, preview and rollback.
22. VIP / subscription — benefits, pricing, purchase/restore, expiry, cancellation and entitlement status.
23. Wallet — balance, ledger history, pending/failed/reversed entries; no client balance mutation.
24. Coins purchase — product list, platform billing, receipt verification, duplicate-safe fulfillment.
25. Gifts — gift catalog, recipient confirmation, ledger debit/credit, delivery and failure recovery.
26. Referral — invite code/link, attribution, eligibility, fraud checks, reward status.
27. Rewards / achievements — eligible tasks, claim idempotency, caps, abuse controls and expiry.
28. Notifications center — preferences, deep-link validation, unread/clear semantics.
29. Settings — account, privacy, safety, language, notifications, accessibility, legal and app version.
30. Block list — unblock flow, consequences and confirmation.
31. Report center / report status — submitted case receipt and status only where policy allows.
32. Help / FAQ / contact — support categories, safe escalation and ticket reference.
33. Account security — active sessions, revoke session, sign-out, suspicious login guidance.
34. Data & account — export request, deletion request, grace period policy, confirmation and completion.
35. Offline / maintenance / restricted region / unsupported version screens.

### 1.2 Next.js public/user website

- Home / landing; product explanation; CTA to Android app; trust and safety.
- About, contact, FAQ/help, community rules, safety center.
- Terms, Privacy, Cookie/consent, Community Guidelines, AI disclosure, billing/refund policies.
- VIP plans/pricing and web checkout only where legally/platform permitted.
- Login callback/status (Google only where web login is supported); account settings and data request portal.
- SEO pages, localization, sitemap/robots, canonical metadata, structured data where appropriate.
- Status/maintenance page and support ticket submission.
- Accessibility, responsive layouts, consent-aware analytics and ad placements.

### 1.3 Admin Console (Next.js, separate protected surface)

- Admin login, MFA, session/device management, forced re-auth for sensitive actions.
- Dashboard: active users, queues, calls, latency, incidents, revenue, moderation backlog, spend.
- User search/detail: account status, risk signals, sessions, sanctions, privacy-safe audit view.
- Moderation queue: report triage, evidence access under strict authorization, case notes, actions.
- Sanctions: warn, temporary suspend, permanent ban, feature restriction, expiry, reason and appeal.
- Appeals: intake, reviewer assignment, decision, user notification, immutable audit.
- Matchmaking configuration: safe thresholds, rollout, feature flags, rollback, change history.
- LiveKit/provider operations: region health, token issuance policy, capacity and kill switches.
- AI translation: providers, supported languages, consent rates, latency, budget, caps, fallback and kill switch.
- Economy: products, VIP plans, gifts, coin packs, rewards, referral rules, limits and effective dates.
- Payment operations: webhook health, reconciliation, refunds, disputes, duplicate and fraud review.
- CMS: pages, FAQ, notices, localization, SEO metadata, publish/preview/rollback.
- Ads: placements, frequency caps, consent, exclusions, no-active-call rule and kill switch.
- Analytics: funnels, retention, cohorts, experiments, privacy controls and data export governance.
- Feature flags / experiments: audience, allocation, guardrails, audit and rollback.
- RBAC: role/permission matrix, least privilege, separation of duties, admin action audit.
- Security operations: alerts, rate limits, abuse patterns, key rotation reminders, incident tools.
- Infrastructure: health, SLOs, queue depth, DB pool, region failover, backup/restore evidence.
- Cost console: AI/video/infra/payment/ad cost, thresholds, alerts, hard limits and emergency disable.
- Support: ticket search, safe account assistance, escalation and response SLA tracking.

## 2. Core domain engines (logical modules; not a claim of separate microservices)

1. Identity & OAuth Engine — Google token verification, immutable subject, session lifecycle, revocation.
2. Age Assurance & Eligibility Engine — age evidence/state, jurisdiction rules, restricted access.
3. Consent & Privacy Engine — versioned consent, purpose, withdrawal, data visibility.
4. Profile Engine — validation, media moderation, public/private fields.
5. Presence Engine — online/away/busy/offline, TTL, visibility and stale-state cleanup.
6. Preference Engine — languages, interests, regions, exclusions, privacy-aware filters.
7. Matchmaking Engine — eligibility, candidate ranking, queue, atomic reservation, fairness, fallback.
8. Match Session Engine — offer/accept/decline, timeout, duplicate prevention, state transitions.
9. Realtime Signaling Engine — authenticated signaling, session-bound permissions and abuse limits.
10. Video Room Engine — LiveKit room/token, participant grants, expiry, region selection.
11. Network Quality Engine — reconnect, ICE/TURN diagnostics, bitrate adaptation and quality metrics.
12. Call Lifecycle Engine — start/end, disconnect reasons, duration, cleanup and post-call events.
13. Skip/Cooldown Engine — server-side 15-second normal skip lock; safety exits exempt.
14. Safety/Report Engine — report intake, category, evidence policy, case creation and triage.
15. Block/Trust Engine — bidirectional exclusion, no rematch, messaging/call restrictions.
16. Moderation & Sanction Engine — enforcement, expiry, appeals, reviewer controls.
17. Chat Engine — message authorization, rate limits, delivery semantics, retention and deletion.
18. Friend Graph Engine — requests, mutual friendship, removal, privacy-aware presence.
19. Private Call Consent Engine — request lifecycle, consent, expiry, quotas and eligibility.
20. AI Translation Engine — consent, language routing, transcription/translation/voice, fallback.
21. AI Cost & Safety Engine — quotas, token/audio limits, provider failure, abuse/cost kill switch.
22. Subscription & Entitlement Engine — purchase validation, active entitlements, expiry/grace.
23. Wallet/Ledger Engine — immutable double-entry or balanced ledger, idempotent transactions.
24. Payment Engine — app-store/web payments, signed webhook, verification, reconciliation/refunds.
25. Gift Engine — catalog, price, debit/credit, delivery, idempotency and reversal.
26. Referral/Reward Engine — attribution, eligibility, caps, anti-fraud and claim idempotency.
27. Notification Engine — FCM/email where approved, preferences, templates, deep-link safety.
28. Ads Engine — eligibility, consent, frequency, placement, exclusion during active call.
29. Analytics/Experiment Engine — event schema, minimization, cohort, A/B and guardrails.
30. Admin/RBAC/Audit Engine — permission checks, MFA, reason-required actions and append-only audit.
31. CMS/Localization Engine — versioned content, review, publish, rollback and locale fallback.
32. Billing/Cost Governance Engine — provider budgets, thresholds, alerts and circuit breakers.
33. Data Lifecycle Engine — retention, export, deletion, legal hold policy and backups.
34. Global Routing/Resilience Engine — region selection, health, failover and degradation behavior.
35. Support Engine — ticket lifecycle, identity verification and escalation.

## 3. Critical state machines

### Match
`IDLE → QUEUED → CANDIDATE_RESERVED → OFFERED → ACCEPTED → ROOM_ALLOCATING → CONNECTING → ACTIVE → ENDED`.
Terminal/alternate states: `CANCELLED`, `TIMED_OUT`, `NO_MATCH`, `REJECTED`, `FAILED`, `SAFETY_TERMINATED`. Every transition must be authenticated, atomic where needed, idempotent, observable and tested.

### Call
`CREATED → TOKEN_ISSUED → CONNECTING → ACTIVE → RECONNECTING (optional) → ENDED`.
Failure states include `TOKEN_EXPIRED`, `ROOM_FAILED`, `PEER_DISCONNECTED`, `NETWORK_FAILED`, `SAFETY_ENDED`. Room access and token grants must be participant/session scoped and expire.

### Private-call request
`REQUESTED → ACCEPTED | REJECTED | IGNORED | WITHDRAWN | EXPIRED`; only accepted requests may create a room, and both users must remain eligible/unblocked.

### Report/moderation
`SUBMITTED → TRIAGED → INVESTIGATING → ACTIONED | DISMISSED → APPEAL_PENDING (optional) → APPEAL_RESOLVED`.
Evidence access is role-, case-, and purpose-restricted; retention is policy-controlled.

### Payment / wallet
`PAYMENT_PENDING → VERIFIED → FULFILLED`; alternatives `FAILED`, `REFUNDED`, `REVERSED`, `DISPUTED`. Fulfillment is webhook-verified and idempotent; balance is derived from ledger, not client input.

## 4. API and event contract inventory (to be specified before production)

- Auth/session: OAuth callback exchange, session refresh/revoke, eligibility status.
- Profile: read/update, media upload intent/finalize, privacy preferences.
- Presence: heartbeat, status and privacy-aware lookup.
- Match: preferences, enqueue, cancel, offer response, skip, match status.
- Call: room/token request, lifecycle heartbeat/end, quality report.
- Safety: report, block/unblock, case receipt, appeal submission.
- Friends: request/list/accept/decline/remove.
- Messages: conversation list, send, delivery/read, mute/archive.
- Private call: request, accept/reject/ignore/withdraw, status.
- AI: translation session start/stop, language config, consent, quota status.
- VIP: catalog, purchase/restore, entitlement.
- Wallet: ledger history, coin product, verified purchase status.
- Gifts: catalog, send, delivery status.
- Referrals/rewards: code, attribution, status, claim.
- Notifications: preferences, unread, read/clear.
- Account/data: export, deletion, session revoke.
- Admin: case, sanction, appeal, config, feature flag, billing, CMS, analytics, cost and audit APIs.

Realtime events must be versioned and include event ID, actor/session context, timestamp, schema version, authorization rule, retry/idempotency behavior and privacy classification. Do not trust client-generated events for financial, eligibility or enforcement decisions.

## 5. Data model groups (initial logical inventory)

- Identity: `users`, `auth_identities`, `sessions`, `age_assurance`, `eligibility_decisions`.
- Consent/privacy: `consent_records`, `privacy_settings`, `data_requests`, `retention_jobs`.
- Profile: `profiles`, `profile_media`, `profile_moderation`.
- Presence/matching: `presence`, `match_preferences`, `match_queue`, `match_sessions`, `match_events`.
- Calls: `call_sessions`, `call_participants`, `room_allocations`, `call_quality_events`.
- Safety: `blocks`, `reports`, `moderation_cases`, `moderation_actions`, `sanctions`, `appeals`, `evidence_access_audit`.
- Social/chat: `friend_requests`, `friendships`, `conversations`, `conversation_members`, `messages`, `message_receipts`, `private_call_requests`.
- AI: `translation_sessions`, `ai_usage`, `provider_usage`, `ai_budget_events`.
- Economy: `products`, `subscriptions`, `entitlements`, `wallet_accounts`, `ledger_transactions`, `ledger_entries`, `purchases`, `payment_webhooks`, `refunds`, `gifts`, `referrals`, `reward_claims`.
- Platform: `notifications`, `notification_preferences`, `cms_pages`, `feature_flags`, `experiments`, `analytics_events`, `support_tickets`.
- Admin/ops: `admin_users`, `roles`, `permissions`, `role_permissions`, `admin_audit_logs`, `system_configs`, `provider_health`, `incidents`, `cost_alerts`.

Names are logical placeholders; final SQL schema, indexes, constraints, RLS and migrations must be reviewed and tested.

## 6. Security, privacy, abuse, and resilience checklist

- OAuth state/nonce/PKCE as applicable; verified issuer/audience/signature; secure session rotation and revocation.
- Server-side authorization on every object/action; deny-by-default RLS; IDOR and cross-user tests.
- Age/region eligibility checked on every relevant entry point and revalidated for sensitive flows.
- Rate limits and risk controls for signup, queue, skip, messaging, requests, uploads, referrals, rewards and reports.
- Block is enforced across matchmaking, private calls, friend requests and messages; race conditions tested.
- Admin MFA, least privilege, separation of duties, reason codes, immutable audit, sensitive-action confirmation.
- Webhook signature verification, replay protection, idempotency keys, reconciliation and refund/dispute paths.
- Ledger invariants, concurrent spending tests, no negative balances, no duplicate reward/purchase.
- LiveKit grants scoped to room/participant/permissions, short-lived, no token leakage in logs.
- AI provider secrets server-only; prompt/data minimization; consent, retention, quotas and kill switch.
- Upload MIME/content validation, malware/abuse screening, signed URLs, access and retention limits.
- Data export/deletion workflow, backups, legal hold policy, restore verification and audit.
- SLOs, alerting, graceful degradation, regional failover drills and incident runbooks.
- Dependency scanning, secret scanning, SBOM/release provenance and secure CI.

## 7. Test and acceptance layers

- Unit: domain rules, state machines, matching eligibility, ledger invariants, consent and sanctions.
- Integration: OAuth, DB/RLS, LiveKit token/room, payment webhooks, AI provider, FCM, storage.
- API contract: schemas, versioning, auth, errors, idempotency and rate limits.
- E2E: sign-in → eligibility → match → call → report/block → post-call; friend/chat/private call; purchase → ledger → gift.
- Security: IDOR, RLS bypass, token replay, admin privilege escalation, webhook spoof/replay, race conditions, abuse automation.
- Mobile: permissions denied/regranted, background/foreground, incoming interruption, low bandwidth, reconnect, device rotation and app kill.
- Load: queue, signaling, calls, chat, webhooks, AI budgets and regional capacity.
- Accessibility/localization: keyboard/screen reader, contrast, RTL where needed, Hindi/English and locale fallbacks.
- Release gates: no unresolved critical/high security defects; safety, age, payment, deletion and recovery gates passed; verified rollback and incident contacts.

## 8. Decisions requiring explicit product/legal/engineering approval

1. Age assurance provider and country-by-country eligibility.
2. Gender preference semantics, allowed filters and fairness/legal review.
3. Location/nearby behavior and precision/retention policy.
4. Skip cooldown exact start/end semantics and edge cases.
5. Maximum call duration, device matrix and supported Android versions.
6. Private call availability, quotas and whether any pricing exists (default no pay-to-safety).
7. Message encryption model, retention, deletion and reporting/evidence behavior.
8. AI vendor, languages, translated voice implementation, region, retention and per-user cost caps.
9. VIP, coin packs, gift values, refunds, taxes, app-store compliance and web checkout.
10. Reward/referral caps, fraud thresholds and eligibility.
11. Ad consent, regions, placements, frequency and policy review.
12. Moderation SLAs, evidence retention, appeals and escalation.
13. Regions, data residency, localization and global routing.
14. Availability SLO, RPO/RTO, capacity and disaster recovery.
15. Analytics events, privacy minimization, experiments and retention.
16. Final service boundaries, monolith/modular backend and deployment topology.

## 9. Definition of complete implementation

A feature is not complete because a screen or button exists. It is complete only when its requirement ID maps to UI/control, state and errors, server function, API/event, schema/constraints, auth/RLS, privacy/safety/abuse controls, dependencies, telemetry, tests, acceptance evidence and operational ownership. Integrations must be exercised in a test environment; mocked behavior must be labeled. Production readiness requires approved legal decisions, passed gates, monitoring, recovery and rollback evidence.

## 10. Execution order (without reducing final scope)

1. Resolve critical decisions and architecture ADRs; keep all features in the integrated scope.
2. Establish monorepo structure, lint/format/typecheck/test CI and environment/secrets policy.
3. Implement identity, eligibility, consent, profile and RLS foundations.
4. Implement presence, queue/matching, signaling, LiveKit and call lifecycle.
5. Implement block/report/moderation and safety-critical flows before broad launch.
6. Implement social graph, chat and consent-based private calls.
7. Implement AI translation behind opt-in, budgets and kill switches.
8. Implement subscriptions, ledger, payments, gifts, referrals and rewards.
9. Implement admin, CMS, analytics, support, cost and operations controls.
10. Globalization, resilience, load/security testing, release gates and rollout.

**Truth status:** Scope/catalog documented. App code, database migrations, provider integrations, automated tests and production deployment are not asserted as complete by this document.