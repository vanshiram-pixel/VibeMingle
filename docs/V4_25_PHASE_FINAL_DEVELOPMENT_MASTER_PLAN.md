# VibeMingle V4 — 25-Phase Final Development & Launch Master Plan

**Status:** FINAL PHASE PLAN / HARD-LOCKED PRODUCT SEQUENCE  
**Date:** 2026-11-15  
**Branch:** feat/typing-presence  
**Authority:** V4_FINAL_HARD_LOCKS.md + V4_COMPLETE_PRODUCT_REVIEW_AND_LAUNCH_LOCK.md  
**Important:** This document locks scope, order and exit criteria. It does NOT mark work completed. Phase statuses must be evidenced in the roadmap.

## 0. Execution rules (non-negotiable)

1. Work phase-by-phase, in order, with dependency exceptions documented.
2. A phase is complete only when its deliverables are coded, integrated, acceptance-tested, security-reviewed where relevant, and evidence recorded.
3. UI-only, schema-only, documentation-only or scaffold-only work is not complete.
4. No fake users/matches/online/calls/translations/payments/rewards.
5. Each feature has one canonical backend owner and is reused by Android, Web and Admin; no duplicated business logic.
6. All mutations require authentication, server authorization, validation, idempotency, rate limiting, RLS/policy and useful error/rollback behavior.
7. Feature flags can hide incomplete features; never advertise them as live.
8. V2/V3 scope is preserved. P0 launch blockers take priority over advanced features.
9. Production deployment, PR merge, app-store publishing and public launch require user notification/approval.
10. Status vocabulary: NOT STARTED → IN PROGRESS → IMPLEMENTED → INTEGRATED → VERIFIED → RELEASED.

## 1. Phase map (25 phases)

| Phase | Name | Exit outcome |
|---|---|---|
| P01 | Repository Audit & Baseline | Known code, gaps, dependencies and status |
| P02 | Architecture & Contracts | Shared domain/API/state/event design |
| P03 | CI, Environments & Developer Foundation | Reproducible builds and safe configuration |
| P04 | Google Auth & Account Lifecycle | Secure Google-only account flow |
| P05 | Onboarding, Age Eligibility & Consent | Eligible, consented, resumable accounts |
| P06 | Profile, Media & Identity | Complete profile lifecycle |
| P07 | Privacy, Safety & Blocking Foundation | Enforcement across all surfaces |
| P08 | Connections Social System | Friends, requests, follows, followers |
| P09 | Discovery & Presence | Search and truthful privacy-aware presence |
| P10 | Canonical Chat & Messaging | Reliable realtime one-to-one messaging |
| P11 | Notifications & Deep Links | In-app + push event delivery |
| P12 | Matchmaking Engine & Queue | Atomic eligible stranger pairing |
| P13 | Stranger Video Session | Real match WebRTC + safe controls |
| P14 | Private Audio/Video Calls | Request/accept/real call lifecycle |
| P15 | Moderation & Admin/Ops Launch Console | Operable safety and support |
| P16 | Website/PWA Core Parity | Responsive web core experience |
| P17 | AI, Translation & Communication Enhancements | Consent-based advanced communication |
| P18 | VIP, Coins, Gifts & Payments | Verified financial/ledger services |
| P19 | Rewards, Referrals & Engagement | Fraud-resistant engagement mechanics |
| P20 | CMS, Campaigns & Product Analytics | Content and operational insight |
| P21 | Scale, Reliability & Performance | Capacity, resilience and recovery |
| P22 | Full QA, Security & Compliance Gate | Release candidate evidence |
| P23 | Closed Beta & Feedback Stabilization | Controlled real-user validation |
| P24 | Production Release & Launch | Approved rollout and launch operations |
| P25 | Post-launch Operations & V3 Expansion | Ongoing reliability and scale evolution |

## 2. Detailed phase contracts

## P01 — Repository Audit & Baseline
**Purpose:** establish factual starting point before more code.
- Inventory Flutter/mobile routes, widgets, repositories, state management, dependencies and tests.
- Inventory Supabase migrations, tables, functions, RLS, triggers, realtime policies and current application status.
- Audit current auth, profile, friends, chat, presence, calls, notifications and WebRTC files.
- Identify duplicate repositories/services, schema/UI mismatches, unfinished TODOs, dead buttons, mocks and compile risks.
- Record web/admin absence or existing implementation honestly.
- Create feature matrix: specified / implemented / integrated / verified / released; evidence, blocker, next action.
**Deliverables:** baseline audit, dependency map, prioritized defects, phase status sheet.
**Exit:** every known module classified; no claim of runtime verification without evidence.

## P02 — Architecture & Contracts
- Define app layers: UI → state/controller → domain service → repository/API → backend.
- Canonical API contracts, data models, event names, error taxonomy, pagination and idempotency.
- Shared entities and ownership: account, profile, media, privacy, friend_request, friendship, follow, block, presence, match_queue/session, conversation/member/message/attachment, call, notification, report, admin action, ledger/payment, feature flag.
- Define state machines: auth/onboarding, social request, chat send, match, call, payment, report/moderation.
- Establish design tokens, navigation/deep-link taxonomy and shared UI state.
- Document environment boundaries and secrets.
**Deliverables:** architecture decision records, contracts, state diagrams, schema/API map.
**Exit:** no conflicting duplicate ownership; all later phases use these contracts.

## P03 — CI, Environments & Developer Foundation
- Dev/staging/prod environment separation; secure secrets; no secrets in Git/client.
- Flutter format/analyze/unit-test/build workflow; web/admin CI as projects are introduced.
- Dependency pinning/update policy, vulnerability/license checks, code review/checks.
- Build configuration, crash/error reporting hooks, logging redaction, feature flags.
- Database migration ordering, rollback/forward-fix policy and seed data only for nonproduction.
- Git branching, commit convention, PR checks and artifact versioning.
**Exit:** reproducible CI and environment safety; baseline build/test commands documented and passing where repository supports.

## P04 — Google Auth & Account Lifecycle
- Exactly one Continue with Google login entry; OAuth state/nonce/PKCE as provider supports.
- First login server-side account provisioning; returning Google identity signs in.
- Secure session/token storage, refresh, restore, expiry, logout and revoked-session handling.
- Duplicate tap/loading, cancellation, provider/network errors and retry.
- Account status checks: active, suspended, banned, deleted/pending deletion.
- Account deletion request, confirmation, retention/legal exceptions and anonymization policy.
- No password or alternate OAuth login.
**Tests:** new vs returning account, replay/state failure, expired session, logout, deletion, suspension.
**Exit:** complete real auth lifecycle in staging.

## P05 — Onboarding, Age Eligibility & Consent
- Resumable onboarding, progress and back navigation.
- Adult age verification/eligibility policy appropriate to risk/legal requirements; self-declared age alone not treated as robust verification for stranger video.
- Adult-only stranger matching; minors excluded from that experience.
- Terms, privacy, community rules and versioned acceptance.
- Separate consent: stranger matching, camera/mic, AI/translation processing, media/data handling.
- Display name/username setup handoff, required vs optional steps.
- Contextual OS permission rationale; no forced camera/mic at login.
- Eligibility/consent changes revoke relevant feature access.
**Exit:** onboarding resumes safely; eligibility/consent is server-authoritative and auditable.

## P06 — Profile, Media & Identity
- Display name, unique username, avatar, bio, languages, interests.
- Edit/save/cancel, validation, reserved names and uniqueness race handling.
- Avatar/gallery/intro-video upload: type/size/duration, signed upload, moderation, safe storage, deletion.
- Preview/publish, visibility and discoverability.
- Public profile vs private fields separation; no phone/email/address/exact DOB/exact location disclosure.
- Profile loading/error/empty states; cache refresh and ownership checks.
**Exit:** create/edit/profile/media flows integrated across clients; abusive/invalid upload paths tested.

## P07 — Privacy, Safety & Blocking Foundation
- Profile visibility, discoverability, online visibility, DM and call preferences, match availability.
- Block/unblock with server enforcement; block overrides follow/friend/chat/call/match and active session policy.
- Report user/content/session with categories, optional details/evidence and receipt.
- Safety controls immediately accessible: End, Report, Block, mute, camera-off.
- Account restriction/suspension policy; appeals/support route.
- Consent revocation and privacy/data retention/deletion rules.
- Rate limits, anti-harassment controls, safe error messaging and audit.
**Exit:** policy tests prove blocked users cannot interact via any route/API, not only UI.

## P08 — Connections Social System
- Single Connections hub/tabs: Friends, Requests (sent/received), Followers, Following, Discover People.
- Friend request send/cancel/accept/decline; reciprocal request atomic resolution; remove friend.
- Follow/unfollow independent one-way edge; optional remove follower policy.
- Fans is only alias of Followers; no separate table/count/menu.
- Relationship state precedence on profile/match/discover/chat.
- Shared repository/service/events; unique constraints, idempotency, rate limits, RLS.
- Counts server-derived; no duplicate cards or inconsistent badges.
**Tests:** race requests, repeated taps, block interaction, follow does not grant chat/call.
**Exit:** all social actions work consistently across screens.

## P09 — Discovery & Presence
- Search username/display name; safe filters and pagination.
- Discover people and privacy-filtered online users; no fake seed users in production.
- Presence heartbeat, TTL, stale/offline cleanup and reconnect.
- Visibility controls and busy/in-call/match state.
- Presence updates in profile, discovery, Connections and inbox consistently.
- Empty/error/offline/retry and rate-limited search.
- Never show precise location or stale “online” as guaranteed live.
**Exit:** real presence/search data, policy enforced and stale state tested.

## P10 — Canonical Chat & Messaging
- One canonical one-to-one conversation per pair/session policy; match conversation reused after friendship.
- Inbox, unread, last-message/time, search/filter, pagination and archive if enabled.
- Realtime text send/receive, history, typing, delivered/read acknowledgments.
- Attachments: image/media validation, secure upload, size/type checks, scanning/moderation.
- Edit/delete own message policy; reply/emoji if included in V4 UX.
- Optimistic send with rollback, retry/idempotency, duplicate/out-of-order events.
- Chat permissions, friend/match policy, block/report and conversation safety.
- Chat call buttons initiate requests, never direct connect.
**Exit:** two accounts exchange text/media reliably, reconnect and recover history; RLS and block tests pass.

## P11 — Notifications & Deep Links
- In-app inbox/events: friend request/accept, follow if enabled, calls/missed calls, match/system/safety/support.
- Push provider setup (FCM/APNs/web as applicable), device token lifecycle and permission opt-in.
- Notification preferences per category; quiet/privacy behavior.
- Read/unread acknowledgment; deduplication and delivery retries.
- Deep link opens exact authorized request/profile/chat/call; fallback if expired/unauthorized.
- No sensitive message/call contents on lock screen by default.
**Exit:** essential events survive push failure in inbox and deep links enforce auth/ownership.

## P12 — Matchmaking Engine & Queue
- Three modes: Instant Random; Random Switch/Next; Manual Search.
- Manual filters: approved gender preference, adult age band, language and safe optional filters.
- Eligibility: verified adult status, consent, active/present, not busy/suspended, device readiness policy.
- Atomic reservation/pairing, one active session per user, idempotent Start/Next/Cancel.
- Block both directions, recent pair/skip cooldown, fairness, queue cleanup/TTL.
- No silent filter broadening; empty queue remains searching until cancel.
- Server events/session IDs, heartbeat, stale/out-of-order event protection.
- Metrics: queue time, match success, cancel, pairing failure and abuse rates.
- Target <1s initial pair and 1–2s Next only when compatible peer is waiting; never promise guaranteed latency.
**Exit:** concurrency/race tests, no duplicate/ghost sessions, real eligible pair only.

## P13 — Stranger Video Session
- Real WebRTC peer session, signaling, ICE/STUN/TURN and secure TURN credentials.
- Auto-connect after server match; no second accept prompt.
- Remote video stage/local preview; camera/mic permission and device selection.
- Mic mute, camera on/off, flip camera, speaker/audio route, chat panel.
- Next disabled for 15-second minimum; visible countdown; End/Report/Block/mute/camera off always immediate.
- Next ends old session correctly; both users' intent/state resolved without ghost requeue.
- Network change, reconnect, ICE failure, device busy, permission denial, call quality and retry/End.
- No recording by default; explicit disclosure/consent if policy ever changes.
**Exit:** two-user/two-device tests across networks, safety controls verified, real media confirmed.

## P14 — Private Audio/Video Calls
- Audio or video call request from permitted profile/chat.
- Preflight: friend/relationship policy, privacy, availability, block, account safety.
- Outgoing ringing/cancel/timeout/busy/declined/accepted states.
- Incoming call overlay Accept/Decline; only Accept starts private media.
- WebRTC/TURN, mic/camera/speaker/flip/end/reconnect and call quality.
- Missed/declined/ended call history; notification and privacy.
- No friend status alone creates call consent; no old stranger session rejoin/direct-call.
**Exit:** full caller/callee lifecycle and denial/failure paths tested.

## P15 — Moderation & Admin/Ops Launch Console
- Staff-only auth/RBAC and least privilege; roles support/moderator/ops/content/finance/super-admin.
- User search/status, age eligibility status without DOB exposure, warn/restrict/suspend/ban/unban with reason/duration.
- Report queue, severity/priority, evidence metadata, reviewer notes, resolve/escalate/appeal.
- Block/report abuse signals; repeat offender and incident handling.
- Match/queue/session health by opaque ID; safe kill switch and feature flags.
- Support tickets, user communication, audit trail, privileged-action logging.
- No private call media access by default; evidence access restricted/audited.
**Exit:** moderator can review/act safely; permissions and audit tests pass.

## P16 — Website/PWA Core Parity
- Public landing, How It Works, safety/community, Terms, Privacy, FAQ/contact.
- Google-only auth, onboarding, Home, Discover, Profile/Edit, Connections.
- Match lobby/manual filters/active video room with chat and safety controls.
- Inbox/thread, incoming/outgoing calls/history, Notifications, Settings/Privacy/Safety, Help/Report.
- Responsive desktop/tablet/mobile, keyboard, screen reader, safe viewport and browser camera/mic permissions.
- PWA install/offline shell; offline mode never claims live match/call.
- SEO metadata, canonical URLs, sitemap/robots and accessible design.
- Same backend and authorization; no separate web-only logic.
**Exit:** core web user journey tested; any unsupported launch surface clearly documented and not marketed as live.

## P17 — AI, Translation & Communication Enhancements (V2)
- Opt-in speech transcription/language detection and translation.
- Target language, captions on/off, original/translated audio choice, translated voice mute.
- Original text/audio remains distinguishable; translated content labeled.
- Consent, provider disclosures, retention controls, privacy and provider secrets server-side.
- Graceful provider unavailable/latency/error; original audio/text fallback.
- Text chat translation explicit action or opted-in inline display.
- AI-assisted safety triage only as aid; human moderation authority, false-positive review.
- AI profile/help suggestions only with consent and bounded data.
**Exit:** translation quality/latency/privacy tests; no fake translation; flags control rollout.

## P18 — VIP, Coins, Gifts & Payments (V2)
- VIP plan/catalog, subscription purchase/renew/cancel/status.
- Coin purchase and balance; gift inventory, send/receive and display.
- Transaction history, receipts, pending/failed/refund/reversal.
- Server-authoritative price/balance; append-only ledger; idempotency.
- Payment provider integration and verified signed webhooks; reconciliation.
- Fraud/chargeback controls, purchase limits and finance RBAC.
- Client never edits balance or claims payment success without verified provider state.
- Feature flags hide non-live purchase routes.
**Exit:** sandbox and reconciliation tests pass; financial security review before real money.

## P19 — Rewards, Referrals & Engagement (V2)
- Achievements, streaks, missions/challenges and referral invite/code.
- Eligibility/progress, claim/expiry and reward history.
- Server-side award/claim idempotency; fraud, bot and referral abuse controls.
- Terms, privacy and clear reward status; no guaranteed earnings deception.
- Notification/in-app progress and opt-out where appropriate.
**Exit:** duplicate/abuse/eligibility tests and ledger consistency.

## P20 — CMS, Campaigns & Product Analytics
- Admin-managed FAQ, safety/community content, banners/notices and campaigns.
- Draft/preview/publish/rollback; permissions and audit.
- Feature flag management, gradual rollout and emergency disable.
- Analytics funnels: auth/onboarding, match, chat/call, retention, reliability, safety and monetization.
- Privacy-minimized events, retention and access policy; aggregate dashboard.
- Support metrics, incident/status communication and export controls.
**Exit:** content safely publishable, metrics validated, access audited.

## P21 — Scale, Reliability & Performance
- Capacity/load testing for auth, realtime, presence, queue, chat, calls and notification.
- Database indexes, query plans, connection limits, queue/realtime scaling.
- Rate limits, abuse protection, circuit breakers/backoff and graceful degradation.
- Observability: logs, metrics, traces, crash/error alerts and redaction.
- Backup/restore drills, disaster recovery, data retention and incident runbooks.
- CDN/media storage, upload limits and cache invalidation.
- Region/network performance and WebRTC/TURN capacity planning.
**Exit:** defined SLOs, load results, alerting and recovery evidence; bottlenecks resolved or launch limits documented.

## P22 — Full QA, Security & Compliance Gate
- Unit, widget/UI, integration, API, RLS, E2E and regression suites.
- Two-user/two-device match/chat/call workflows; Android + supported browsers.
- Auth/OAuth, ownership, RLS, storage, admin RBAC, secrets, dependency and penetration/security review.
- Race/idempotency, duplicate taps, stale events, reconnect, offline, permission denial, poor network.
- Accessibility, localization, device sizes, battery/data and performance.
- Abuse, report/block, age eligibility, consent, privacy, deletion/retention and legal review.
- Payments/rewards security if enabled.
- Bug severity: release-blocking critical/high issues must be resolved.
**Exit:** signed test report, zero open launch-blocking defects, privacy/security review evidence.

## P23 — Closed Beta & Feedback Stabilization
- Invite-only/controlled tester cohort; staging or controlled beta build.
- Beta consent, feedback/report channel, crash analytics and feature flags.
- Real usage validation of onboarding, Connections, match, chat, private calls and safety.
- Monitor match success/latency, call quality, crash-free sessions, abuse and support load.
- Triage feedback, fix blockers, retest and regression.
- Rollback/disable features if safety/reliability degrades.
**Exit:** beta criteria met, issues resolved, product/support readiness signed off.

## P24 — Production Release & Launch
- Final release candidate, versioning, signing, store metadata/screenshots, privacy labels/disclosures.
- Production environment/config/secrets, database migration plan, backup and rollback.
- Monitoring dashboards, alerts, support/moderation staffing and incident contacts.
- Gradual rollout/feature flags, health checks and release notes.
- App store submission and web deployment only after explicit user approval.
- Confirm Google auth, data protection, age/safety policy, support and legal requirements.
- Post-release smoke test and rollback decision.
**Exit:** approved production release, real smoke-test evidence and launch status recorded.

## P25 — Post-launch Operations & V3 Expansion
- Daily reliability/safety/abuse/support review; incident response and release cadence.
- Patch, security updates, dependency upgrades and regression.
- User feedback, retention/quality analytics and roadmap prioritization.
- Expand translation, smart matching, personalization, creator ecosystem and global scale gradually.
- Advanced trust/safety, moderation automation with human oversight.
- Capacity planning, cost controls, disaster recovery drills and feature experiments.
- V3 expansion remains evidence-led and does not destabilize core.
**Exit:** continuous operations process and next release roadmap; not a terminal phase.

## 3. Phase completion report (required every phase)

Each phase report must include:
- Phase ID/name and scope.
- Files/modules changed and commit(s).
- Backend/schema/API changes and migration status (created vs applied).
- Android/Web/Admin surfaces integrated.
- Tests run and exact results; tests not run clearly stated.
- Security/RLS/abuse checks.
- Known limitations/blockers and next phase dependencies.
- Status label: SPECIFIED / IN_PROGRESS / IMPLEMENTED / INTEGRATED / VERIFIED / RELEASED.
- User-facing concise summary in Hindi.

## 4. Launch-critical dependency chain

P01 → P02 → P03 → P04 → P05 → P06 → P07 → P08 → P09 → P10 → P11 → P12 → P13 → P14 → P15 → P16 → P21 → P22 → P23 → P24.

P17–P20 may be developed in parallel or after stable core, but do not block core launch unless explicitly enabled/advertised. P25 begins after launch and continues indefinitely.

## 5. Final hard lock

- This 25-phase sequence is the default execution plan.
- Phase scope and exit criteria are locked; user-approved change requests can amend it.
- Do not skip a phase silently or call a phase complete without evidence.
- Do not expand scope while launch-critical phase is unfinished, except necessary security/reliability fixes.
- The immediate next action after this plan is P01 repository audit and baseline, then proceed in order.
- Final launch is not authorized by this plan; production/store/public release requires explicit user approval.
