# VibeMingle V1–V4 Reconciliation & Repository Evidence Audit

**Audit date:** 2026-11-15  
**Branch:** feat/typing-presence  
**Purpose:** Reconcile V1/V2/V3 scope with V4 and separate specification from repository/runtime evidence.  
**Status:** Audit snapshot; NOT a final user seal or runtime certification.

## 1. Version-to-V4 reconciliation (all scope retained)

Version labels are scope tiers; V4 is unified authority. No feature is removed merely because it is post-launch.

### V1 — Core social/video product
- Android + website; Google-only authentication (later hard lock supersedes any earlier auth alternative).
- First Google sign-in provisions account; returning sign-in; onboarding/profile.
- Profile/avatar/bio/languages/interests and profile editing/media.
- Discover/search people; privacy-aware online/presence.
- Friends, friend requests, follow/unfollow, followers/following.
- Stranger video matching: instant/random, gender preference; geographic scope ideas (Nearby/Country/Worldwide) remain subject to safe/legal policy. V4 includes Manual Search age/language filters and server eligibility.
- Stranger video: auto-pair, local/remote video, mic/camera/switch/quality/reconnect, text chat, End/Next/Report/Block.
- Private one-to-one chat, emoji and friend/match flows.
- Private audio/video calling with request/accept; call states/history.
- Notifications, settings, privacy, safety, report/block.
- Admin/moderation/support, Supabase backend, analytics baseline, Android/web.
- Launch acceptance: real auth/profile/social/chat/match/calls/safety, RLS, notifications, admin operations and test evidence.

### V2 — Advanced communication, intelligence and monetization
- Smart matching/ranking and richer preferences/filters.
- AI-assisted moderation/triage (human moderator remains authority) and AI assistance.
- Voice transcription, language detection, live translation, captions and optional translated audio; original audio/text fallback.
- Enhanced social/engagement and video quality.
- VIP/subscriptions, coins, gifts, rewards.
- Ads, referrals/campaign mechanics, analytics and automation/operations.
- Payment provider, ledger, receipts, verified webhooks, refund/reconciliation.
- V2 gates: consent/privacy, feature flags, anti-fraud, financial integrity and provider failure handling.

### V3 — Scale, personalization and ecosystem
- Personalization/recommendations and intelligent/global matching.
- Nearby/Country/Worldwide matching expansion only with safety, privacy, fairness and legal rules.
- Multi-region architecture/capacity, global reliability/performance.
- Creator ecosystem and richer creator/profile/video capabilities.
- Advanced trust/safety, moderation automation with human oversight and enterprise operations.
- Global analytics, experimentation, operations and ecosystem integrations.
- V3 must not destabilize V1; staged rollout.

### V4 — Unified authority
- Consolidates V1–V3 into one screen inventory, shared service/data ownership, state/event contracts, permissions, acceptance tests, phases and launch gates.
- Connections is the sole social hub; Fans aliases Followers.
- Canonical conversation; match chat reused after friendship; private call always request→accept.
- Three matching modes share one server engine; no silent filter fallback or fake match.
- P0 Core launches first; V2/V3 remain preserved, flagged and phased.
- Every status is evidence-based; production launch requires user approval.

## 2. Screen/page crosswalk: controls and phase ownership

| Screen/Page | Action families (buttons/controls) | Phase |
|---|---|---|
| S00 Splash/bootstrap | Retry, offline guidance, update route; session/account validation | P03–P04 |
| S01 Google Auth | Continue with Google, cancel, retry, Terms, Privacy | P04 |
| S02 Onboarding | Back, Continue, optional Skip, consent toggles, eligibility verification, finish/resume | P05 |
| S03 Home | Instant Match, Manual Search, Discover, Connections, inbox, notifications, profile, help | P06–P11 |
| S04 Match Lobby | Mode selector, filters, Apply, Reset, Start, Cancel, retry | P12 |
| S05 Active Match | Mute, camera, flip, speaker, chat, Add Friend, Follow, profile, Next, End, Report, Block | P08/P12/P13 |
| S06 Post-match | Add Friend, Follow, Continue Chat, Next Match, Home, Report, Block | P08/P10/P12/P13 |
| S07 Discover/Search | Search, filters, online filter, pagination, profile, friend/follow/message/call actions | P08/P09/P14 |
| S08 Public Profile | Add/Cancel/Accept request, Friends/Remove, Follow/Unfollow, Message, Video Call request, Report, Block | P06–P08/P10/P14 |
| S09 Edit Profile/Media | Edit fields, upload/preview/publish/remove media, visibility, Save, Cancel | P06 |
| S10 Connections | Friends, Requests received/sent, Accept/Decline/Cancel, Followers, Following, Unfollow, Discover | P08 |
| S11 Chat Inbox | Search, filters, open, unread, archive (if enabled), pagination | P10/P11 |
| S12 Chat Thread | Send, retry, emoji, attach, edit/delete, reply (if enabled), typing/read, Report/Block, audio/video call request | P10/P11/P14/P17 |
| S13 Private Calls | Audio/Video request, Cancel, Accept, Decline, End, mic/camera/speaker/flip, reconnect, history | P14 |
| S14 Notifications | Open/deep link, mark read/unread, preferences, push opt-in | P11 |
| S15 Settings/Privacy/Safety | Logout, delete account, visibility/privacy, blocked list/unblock, consent, language/accessibility/theme, notifications | P04/P05/P07/P11 |
| S16 Wallet/VIP/Coins/Gifts | Plan view, buy/renew/cancel, coin purchase, gift send, ledger/history, receipt/refund state | P18 |
| S17 Engagement | Achievement/missions, streak, referral, progress, claim, history/opt-out | P19 |
| S18 Help/Report/Support | FAQ, create ticket/report, submit, status, appeal/contact | P07/P15/P20 |
| S19 Global overlays | Incoming call Accept/Decline; friend request Accept/Decline; permission Continue/Not now; destructive confirmation; retry/offline/rate limit | P04/P05/P07/P11/P14 |
| Web public pages | Landing, How it works, Safety, Terms, Privacy, FAQ, Contact, SEO, PWA install | P16 |
| Web authenticated | Auth/onboarding, Home, Discover, Profile, Connections, Match/Video, Chat, Calls, Notifications, Settings, Help | P16 |
| Admin dashboard | Health, queue/session metrics, reports, notification/payment/release status | P15/P20/P21 |
| Admin users | Search, safe profile/status, warn/restrict/suspend/ban/unban with reason/duration | P15 |
| Admin moderation | Queue, priority, evidence metadata, review, action, resolve/escalate/appeal | P15 |
| Admin match/ops | Queue health, session inspect, flags/kill-switch, incident actions | P15/P20/P21 |
| Admin CMS/flags | Draft, preview, publish, rollback, flags, rollout, emergency disable | P20 |
| Admin finance | Plans, catalog, payment/ledger, refund/reconciliation, audit | P18 |
| Admin analytics/support/audit | Funnel, reliability/safety trends, tickets, audit search/export | P15/P20 |

**Universal button contract:** visibility/precondition; enabled/disabled and duplicate-tap behavior; exact service/API/event; authorization; idempotency; authoritative success; error/retry/rollback; audit/analytics; accessibility/focus; test case. No button is complete until applicable parts are implemented and tested.

## 3. Current GitHub repository evidence (branch snapshot)

Repository tree contains:
- Flutter mobile entry/app shell: apps/mobile/lib/main.dart, apps/mobile/lib/src/app.dart.
- Calling: call_models.dart, call_repository.dart, incoming_call_screen.dart, webrtc_call_controller.dart.
- Friends: friend_repository.dart, friends_screen.dart.
- Messaging: chat_repository.dart, chat_repository_v2.dart, chat_thread_screen.dart, messaging_screen.dart, presence_controller.dart.
- Presence: presence_repository.dart.
- Supabase migrations: 0001_call_sessions.sql, 0002_friend_requests.sql, 0003_private_chat.sql, 0004_user_presence.sql, 0005_notification_preferences.sql, 0006_profiles.sql.
- Docs: call setup/signaling, chat/notifications/UI integration, friend system, matching, presence lifecycle, private chat, typing/presence, V4 locks, blueprint, roadmap and phase plan.

### Evidence status (do not overclaim)
- **Code present:** Flutter shell and initial feature files/repositories/screens for calling, friends, chat and presence.
- **Schema files present:** six migrations; file presence does not prove migrations were applied to Supabase.
- **Specified/documented:** matching, private call, chat, presence, friend flow and V4 requirements.
- **Not evidenced by current tree:** dedicated web app, Admin/Ops app, implemented matchmaking engine/queue, production AI/translation, payments/ledger, coins/gifts/rewards/referrals/ads, creator/global multi-region system, complete moderation console, full test suite/CI/release artifacts.
- **Not verified from repository browsing:** Flutter compile/device run, OAuth provider config, Supabase migration application, RLS tests, realtime two-user flows, WebRTC/TURN across networks, push delivery, production security/performance, store release.
- Duplicate chat repositories and partial screens are audit targets for canonicalization, not proof of complete chat.

## 4. Reconciliation disposition
- Earlier V1/V2/V3 scopes are preserved above and in V4 master. Historical items not present in repo/current recalled notes must be marked RECONCILIATION NEEDED, not silently declared integrated.
- V4 docs are specifications; they do not automatically integrate or implement earlier code/features.
- Every feature needs V1–V3 source, V4 screen/service, phase, status, evidence, dependency and acceptance test.
- No final seal until user reviews detailed phase sheets and approves scope.

## 5. Required artifacts before final seal
1. Feature-by-feature V1/V2/V3 → V4 traceability matrix with unique IDs.
2. P01–P25 expanded phase sheets: screens, buttons, state transitions, APIs/events, data/RLS, errors/rollback, tests and exit criteria.
3. Repository baseline audit with code/migration/test evidence.
4. Missing/duplicate/conflicting requirement register.
5. Final user approval record before scope is treated immutable.
