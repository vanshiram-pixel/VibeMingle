# VibeMingle — Master Roadmap & Scope Control (v1.0)
Updated: 2026-11-15
Branch audited: feat/typing-presence
Repository: vanshiram-pixel/VibeMingle

## Product North Star (LOCKED)
Build the integrated VibeMingle product: Google-only authentication (one Continue with Google entry for signup/login), Android + web, full admin, friend/discovery/matching, private chat, audio/video calls, safety/moderation, AI/translation, notifications, VIP/subscriptions/coins/gifts/ads, analytics/operations, secure scalable infrastructure. V1/V2/V3 are product scope tiers, not permission to skip integrations or quality. Ship a complete, secure launch core first; continue V2/V3 post-launch in planned sequence. Do not change this vision without explicit user direction.

## Audit method
Status means evidence in the current GitHub branch. A migration/file/scaffold is NOT feature-complete. Completion requires implementation + integration + test evidence + security review appropriate to the phase. No live Supabase, Android device, web browser, or production test is asserted unless recorded.

## Current repo evidence (2026-11-15)
- Flutter mobile shell, GoRouter, Supabase auth/session UI (Google-only OAuth not verified)
- Friends screen/repository and migrations
- chat_messages migration + two chat repositories + initial chat thread UI (schema/UI alignment recently started; runtime not tested)
- presence migration/repository
- call session migration/repository, incoming-call UI and WebRTC controller scaffold
- notification/preferences migration
- profiles migration/trigger
- documentation for calling, chat, friend system, presence, notification integration
- No web app, admin app, AI implementation, payments, coins/gifts, ads, production CI evidence or release artifacts in this branch.
- Supabase migrations have not been proven applied; Flutter compilation and end-to-end two-user/device tests are not proven.
- PR #1 remains draft/unmerged; do not merge/deploy until checks and review are green.

## V1 / Launch Core (must be production-grade)
1. Foundation/monorepo, environment, CI, build reproducibility
2. Google OAuth only; account lifecycle, secure sessions, logout, deletion
3. Profile creation/edit, username uniqueness, avatar/media validation
4. Age gate, consent, privacy controls, account safety baseline
5. Friend requests/accept/reject/remove/block; discovery/search
6. Presence/online state and privacy-aware visibility
7. **Instant Stranger Video Matching (V1):** one-tap atomic auto-pairing + automatic call activation (<1s target with waiting peer); 15-second Next lock with immediate safety exits; Next rematch target 1–2s when a peer waits; open-ended visible search + cancel when pool is empty; video-first UI with chat beneath video/bottom sheet, session-integrated controls and translation-ready captions
8. 1:1 private chat: send/receive/realtime, history, pagination, typing, delivered/read, edit/delete, image sharing, block/report
9. Audio/video calling: request/ringing/accept/decline/missed/busy/end, signaling, WebRTC, TURN, permissions, controls, reconnect, call history
10. Push notifications (FCM/APNs/web as applicable), in-app inbox/preferences
11. Reporting/moderation/admin minimum viable operations, ban/suspend, review queue, audit trail
12. Android app + responsive web client; admin panel for launch operations
13. Security/RLS/abuse/rate limits, backups/observability, QA, release, store/web launch

V1 acceptance: a real pair of test users can Google sign in, set profiles, friend each other, discover presence, exchange messages and media, complete audio/video calls across networks, report/block, receive notifications; admin can review/act; data is protected; automated and manual test evidence exists; release can be rolled back.

## V2 / Advanced product
- Smart matching/ranking, richer filters and preferences (beyond V1 basic instant stranger queue)
- AI-assisted translation in chat/calls, language detection and user controls
- Enhanced social features and engagement
- AI moderation triage and abuse/spam detection with human review
- VIP/subscription entitlements, coins, gifts, ad placement/management, payment provider + verified webhooks/refunds
- Analytics dashboards, growth/retention/product experiments
- Admin CMS, advanced support tooling and automation
- Quality, reliability and performance improvements

## V3 / Global scale & ecosystem
- Global personalization and recommendation intelligence\n- Global language routing and scalable real-time translation/media orchestration
- Multi-region/scalable media and backend architecture
- Creator economy/gifts/monetization expansion
- Localization, global policy/compliance and market-specific controls
- Advanced trust/safety intelligence and operations
- Ecosystem integrations and scale optimization

## 15 execution phases (sequence; gates are not skippable)
P01 Foundation & CI
P02 Google Auth & account security
P03 Age, consent, privacy & data lifecycle
P04 Profiles & media
P05 Discovery, presence & friend graph
P06 Basic Instant Stranger Matching (V1) & advanced matching foundations
P07 Messaging (text, realtime, receipts, edit/delete, media)
P08 Calling (signaling, WebRTC, TURN, lifecycle, reliability)
P09 Safety & moderation (report/block/admin workflows)
P10 AI & translation
P11 Monetization (VIP, payments, coins, gifts, ads)
P12 Notifications (push, in-app, preferences, deep links)
P13 Admin & operations (users, moderation, analytics, CMS, audit)
P14 Web client & global infrastructure
P15 QA, security review, staging, release and launch

Dependencies: P01→P02→P03/P04→P05→P06 (presence + age/consent + block/report rules required); P06→P08 (match must hand off into authenticated WebRTC call lifecycle); P05 unlocks P07/P08; P07/P08 feed P09/P12; P09 required before public launch; P10/P11 can be built in parallel after secure core but must have policy/abuse safeguards; P13 is needed before launch for support/moderation; P14 web work can parallelize after API contracts; P15 gates launch.

## Status / honest progress snapshot (2026-11-15)
Percentages below are rough evidence-based engineering estimates, not tests or certification.
P01 Foundation & CI: ~20% (repository/app skeleton exists; CI, environments, repeatable build and branch protection not evidenced)
P02 Google Auth: ~15% (Supabase auth/session UI; Google-only OAuth and lifecycle/security not done)
P03 Age/consent/privacy: ~0–5% (no user-facing flows evidenced)
P04 Profiles: ~25% (schema/trigger; full profile UI, avatar pipeline and validation incomplete)
P05 Friends/presence: ~35% (SQL + initial UI/repositories; integration/privacy/runtime tests missing)
P06 Matching: ~10% (requirements/spec documented in docs/instant-stranger-matching.md; queue, atomic pairing, UI, signaling integration and tests not implemented)
P07 Messaging: ~25% (SQL + repository + basic thread; realtime, typing auth, receipts, media, edit/delete UI and test evidence incomplete)
P08 Calling: ~15% (sessions/RPC/repository and WebRTC scaffold; signaling/TURN/complete call UX/testing missing)
P09 Safety/moderation: ~10% (block/report fragments; full reporting/admin review/escalation missing)
P10 AI/translation: 0%
P11 Monetization: 0%
P12 Notifications: ~10% (schema/preferences only; delivery/push/deep links not implemented)
P13 Admin/Ops: 0% in current branch
P14 Web/global: 0% in current branch
P15 QA/release: 0% (no validated builds, staging or launch)
Overall integrated launch readiness: roughly 10–15%, not a weighted average and not a claim of feature completion.

## Correct direction / scope-drift guard
- We are not abandoning the original vision; the direction is still correct.
- Recent chat work was useful, but coding isolated screens before schema contracts, auth/channel security and tests can create rework. Pause feature expansion and reconcile interfaces first.
- Maintain one canonical schema and one repository per domain; remove legacy messaging schema/RPC references only after migration path is decided.
- Keep PR #1 draft until Flutter analyze/build, SQL validation, RLS tests and two-user integration pass.
- Add a phase checklist, acceptance criteria, blockers, test evidence and status to every phase.
- No "done" label for scaffold/schema-only; use NOT STARTED / IN PROGRESS / IMPLEMENTED / INTEGRATED / VERIFIED / RELEASED.
- Instant stranger matching + integrated video/chat/translation contract: docs/instant-stranger-matching.md. Pairing <1s and Next 1–2s are measured targets only when a compatible peer is waiting; empty queue stays searching with Cancel (no fixed 60–70s timeout). 15s Next lock never blocks safety exit.
- No production deployment, store release or launch without user notification and approval.

## Next execution (ordered)
A. Freeze feature scope and make this roadmap canonical.
B. Audit all Flutter source for compile errors, API mismatch, missing routes and unused legacy files.
C. Establish CI: Flutter format/analyze/test + SQL lint/check; build Android artifact.
D. Configure Supabase staging, apply migrations in order, verify functions/RLS with two users.
E. Finish Google-only auth and profile onboarding.
F. Finish Friends + presence + chat (including receipts, edit/delete, pagination, image bucket, private Realtime authorization).
G. Complete calls end-to-end with signaling + TURN and device/network matrix.
H. Safety/admin launch operations + push notifications.
I. Web client and responsive admin panel.
J. AI/monetization V2; global V3; QA/release gates.

## Risk register (highest)
1. Google OAuth provider/config and mobile redirect/deep links unknown.
2. Migrations are drafts until applied/tested; SQL policies/RPC grants require review.
3. chat row realtime and typing channels need authenticated authorization; public broadcasts must not leak presence/typing.
4. Calling requires signaling auth, TURN credentials, platform permissions and device/network tests.
5. Report/block enforcement must cover chat/call/matching and race conditions.
6. Notification delivery, token storage and deep-link behavior absent.
7. No web/admin code in current branch despite locked scope.
8. Payment webhooks/idempotency/fraud/refund and child safety/privacy need dedicated threat review.
9. No verified CI/build/release/backup/monitoring evidence.

## Definition of complete
Each feature: design/schema → implementation → integration → unit/widget/SQL tests → security checks → staging E2E → acceptance evidence → docs. Only then mark VERIFIED. Launch: all V1 gates green, operational admin and rollback ready, store/web release reviewed with user.


## Canonical detailed product blueprint
Screen-by-screen user journeys, every page/button/popup behavior, V1/V2/V3 scope, Admin/Ops screens, backend wiring, event/state contracts, safety, testing and launch gates are consolidated in [FINAL_MASTER_PRODUCT_BLUEPRINT.md](./FINAL_MASTER_PRODUCT_BLUEPRINT.md). This is the detailed product contract; this roadmap remains the execution/status tracker. Matching/video/chat/translation decisions are also in [instant-stranger-matching.md](./instant-stranger-matching.md).


## Locked social flow contract (2026-11-15)
- Stranger Match → Add Friend → pending request → recipient Accept → mutual Friends.
- Follow is independent; never grants friendship, chat, or private-call permission.
- Match conversation remains canonical after friendship; no duplicate thread.
- After friendship, private call requires Call Request + recipient Accept + privacy/availability/block checks.
- Former match without friendship cannot direct-call or reconnect to old session.
- Block overrides all social, message, match, and call paths.
- Detailed permanent contract: [STRANGER_MATCH_FRIEND_FLOW.md](STRANGER_MATCH_FRIEND_FLOW.md). This is a locked specification, not evidence of implementation.


## Version 4 — Final Hard Locks (2026-11-15)
- V1/V2/V3 preserved as scope/delivery tiers; V4 is the unified authoritative spec, not a claim of implementation completion.
- Final hard locks and acceptance gates: [V4_FINAL_HARD_LOCKS.md](./V4_FINAL_HARD_LOCKS.md).
- Social UI consolidated to one **Connections** hub (Friends, Requests, Followers, Following, Discover People); Fans is not a separate system. Friend remains mutual; Follow remains one-way.
- Matching modes: Instant Random, Next/Random Switch, Manual Stranger Search with adult-only gender/age/language preferences; one shared server matchmaking engine; filters never silently bypassed.
- Profile intro video is preview only; explicit private call request and receiver acceptance required.
- V4 is product scope lock. Actual implementation/integration/verification status must remain evidence-based; production release needs user approval.


## V4.1 — Complete Product Review & Launch Focus Lock
- Full screen/page/control/logic/admin/backend and launch sequence review: [V4_COMPLETE_PRODUCT_REVIEW_AND_LAUNCH_LOCK.md](./V4_COMPLETE_PRODUCT_REVIEW_AND_LAUNCH_LOCK.md).
- Launch focus is P0 Core vertical slices; V2/V3 features remain preserved but must not distract from Core implementation, integration, testing and launch readiness.
- No dead/fake buttons, fake match/call/payment/translation; evidence-based status; deployment/store/public launch only after user approval.


## V4 25-Phase Execution Lock
- [V4 25-Phase Final Development Master Plan](./V4_25_PHASE_FINAL_DEVELOPMENT_MASTER_PLAN.md) is the authoritative phase order, scope and exit criteria.
- Execution begins at P01 repository audit; phase completion requires code + integration + tests + evidence, never docs/UI alone.


## V1–V4 Reconciliation Audit
- [V1–V4 Reconciliation & Repository Evidence Audit](./V1_V2_V3_V4_RECONCILIATION_AND_REPOSITORY_AUDIT.md) records scope preservation, screen/page action crosswalk and evidence-based repository status. No final scope seal is claimed until detailed traceability and user approval.


## V4.2 Advanced Add-ons (2026-11-15)
- Add-on specification: [V4 Advanced Add-ons — Translation, Chat & Security](./V4_ADVANCED_ADDONS_TRANSLATION_CHAT_SECURITY.md).
- Includes advanced manual matching filters + preview; 15-second Next lock with immediate safety exits; live voice translation/captions/audio across stranger/private audio/video calls and all entry points; advanced E2EE chat; privacy-preserving AI safety and case-scoped evidence; IP/device risk monitoring with access controls; Admin service toggles (default ON where supported), emergency stop, hide, rollout, restore, and health monitoring.
- Owner instruction: sexual exploitation/grooming indicators are excluded from general AI monitoring categories. Other specified safety protections remain.
- E2EE constraint: no universal Admin decryption key, covert surveillance, or blanket chat ZIP backup. Export only scoped, user-reported/authorized case evidence with audit, encryption, and retention.
- These are specified add-ons, not implemented/verified functionality. Update all screen/API/event/database contracts and tests during implementation.
