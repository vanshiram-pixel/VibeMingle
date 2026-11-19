# VibeMingle V4 — Complete Screen-by-Screen Product Review & Launch Lock

**Review version:** V4.1 FINAL REVIEW  
**Review date:** 2026-11-15  
**Authority:** This document expands V4_FINAL_HARD_LOCKS.md and FINAL_MASTER_PRODUCT_BLUEPRINT.md.  
**Status:** Product review/specification; not proof of implementation.  
**Primary objective:** Complete, safe Launch Core first. Keep V2/V3 scope in the architecture and roadmap without delaying core launch for nonessential advanced features.

## A. Final scope and operating discipline

### Product surfaces
1. Android application (primary mobile experience).
2. Responsive Website/PWA (public marketing + authenticated product experience).
3. Admin/Ops Console (restricted staff access).
4. Shared backend, database, auth, policies, events and design tokens.

### Version meaning
- V1 = launch core.
- V2 = advanced communication, AI, engagement and monetization.
- V3 = scale, personalization and ecosystem expansion.
- V4 = consolidated product authority, complete screen/action contracts, implementation sequence and launch acceptance. V4 does not mean every V2/V3 feature must ship on day one.

### Hard discipline
- Never create fake matches, fake online users, fake call connection, fake payment success, fake AI translation or placeholder success.
- Every visible button must be wired or explicitly disabled/labelled “coming later” behind a feature flag; no dead buttons.
- One feature has one canonical owner/service/data contract; surfaces reuse it.
- UI spec → code → integration → test → verified evidence. Documentation alone is not completion.
- No PR merge, production deployment, app-store publishing or public launch without user notification/approval.
- Build launch core in vertical slices, not a large disconnected UI-only shell.

## B. Launch scope: must work before first public launch

### Launch P0 (blocking)
- Google-only sign-in, account provisioning, session restore/logout, account deletion process.
- Onboarding, age/safety eligibility, terms/privacy/community consent.
- Profile creation/edit, username uniqueness, avatar/media validation and privacy.
- Connections: friend request/accept/decline/cancel/remove, follow/unfollow, followers/following, block.
- Discovery/search with privacy-aware profile and online state.
- Presence heartbeat/TTL and visibility/privacy.
- Stranger Match: Instant Random, Next/Random Switch and Manual Search filters (adult age eligibility; gender preference, age band, language); atomic server pairing, cancel, 15s Next lock, safety exits.
- Match video session: WebRTC, permissions, mic/camera controls, reconnect/error, End/Next/Report/Block; no fake connection.
- Private chat: realtime send/receive, history/pagination, unread, delivery/read, typing, media validation, block/report.
- Private calls: call request, incoming ring, accept/reject/cancel/timeout/busy/end, WebRTC/TURN, call history and privacy.
- In-app/push notifications for essential requests/calls/safety/system events.
- Report/block/suspend, minimum moderator console, audit.
- Website authenticated core (auth, profile, Connections, discover, match, chat, calls, safety/settings) OR a deliberately documented web launch limitation; do not advertise unavailable web functionality.
- Monitoring, rate limits, RLS/security, backups, recovery, CI, test evidence, rollback and support contact.

### P1 (after stable core / phased)
- Voice translation and AI-assisted chat/call translation, consent, language selection, captions and original-audio fallback.
- Smart ranking/expanded matching preferences, advanced filters.
- VIP, subscriptions, coins, gifts, rewards, ads, referrals, achievements/streaks.
- Creator/intro-video enhancements, campaign/CMS expansion, advanced analytics.
- Multi-region/global scaling and personalization.

**Rule:** P1 remains in V4 master scope and may be developed behind flags, but P0 safety/core reliability takes precedence.

## C. Android application — screen-by-screen and control-by-control contract

## S00 — Splash / session bootstrap
**Display:** brand, build/version, progress; no private information.
- Restore session → validate user/account state → load remote config/feature flags → route.
- Active account → Home; unauthenticated → Auth; incomplete onboarding → resume Onboarding; suspended/blocked account → restricted explanation/support.
- Retry: rerun safe bootstrap; offline: retry/connection guidance; update-required: store/update route.
- No “continue” button that bypasses account/age/suspension checks.

## S01 — Authentication
**Only primary action:** Continue with Google.
- Tap: disable duplicate taps, show progress, launch OAuth with state/nonce/PKCE as supported.
- Success: secure callback, verify identity, server-side account create-or-login, route onboarding/home.
- Cancel: restore button; provider/network error: safe message + Retry.
- Terms, Privacy, Community Rules links open readable pages.
- No email/password or alternative login buttons.

## S02 — Onboarding (resumable steps)
1. **Eligibility:** date/age verification according to law and risk policy; adult-only Stranger Video Match. No public exact DOB.
2. **Consent:** Terms, Privacy, Community Guidelines; separate explicit consent for stranger video, camera/mic, AI/translation processing and any retention.
3. **Identity:** display name, unique username, avatar, optional bio, languages/interests; field validation and retry.
4. **Privacy:** profile visibility, searchable/discoverable, online visibility, message/call permissions.
5. **Permissions:** explain camera/mic at moment of use; Continue does not silently grant device permission.
6. **Finish:** server saves; retry idempotently; route Home.
- Back/Skip only for optional fields; mandatory eligibility/consent cannot be skipped.

## S03 — Home
**Sections:** Start Instant Match; Manual Search shortcut; matching preferences; Discover People; online people (privacy filtered); Connections requests; recent chats; incoming call/request badges; notifications; safety/help.
- Start Instant → Match Lobby with Instant Random selected.
- Manual Search → filter screen.
- Profile/people card → profile.
- Request/notification tile → exact authorized request.
- Chat tile → canonical conversation.
- Empty states explain how to start; loading/error/offline states retry.
- Home never claims a person is online from stale/unverified data.

## S04 — Match Lobby / Search Modes
**Single matching entry, three modes (same engine):**
1. Instant Random: no optional filters beyond safe eligibility/default; Start → queue.
2. Random Switch/Next: active session Next after 15s; compatible peer target 1–2s, not guarantee.
3. Manual Stranger Search: gender preference (supported values including Everyone/men/women/other where lawful and safely implemented), adult age band/custom range, language, optional region/interests only if safe and approved.
- Apply Filters validates choices and saves explicit preferences; Reset restores safe defaults.
- Start Search: server validates consent/eligibility/privacy/block/busy; queue status.
- Cancel Search: removes queue entry idempotently; returns lobby.
- Searching state: “Finding compatible person…” + elapsed/queue state; no arbitrary fixed timeout; Cancel always visible.
- No match: remain searching until cancel; never fake user.
- Filter mismatch: never silently broaden. Explain no compatible peer; let user edit/cancel.
- Age matching uses verified eligibility and policy-safe age bands; exact DOB never displayed.

## S05 — Active Stranger Video Match
**Layout:** remote video stage; movable local preview; adaptive chat panel; persistent safety/control bar.
- Mic: toggle mute; device state reflected.
- Camera: toggle off/on; privacy indicator.
- Flip Camera: switch front/back where supported.
- Speaker/audio route: choose supported route.
- Chat: open/close panel; send text; keyboard/insets resize; video/control visibility preserved.
- Next: disabled until 15s floor; visible countdown; tap after enabled ends current match correctly and enters next search if intent remains active.
- End: immediately ends media/session and leaves queue.
- Report: reason/category/details optional; submit confirmation; safety event; can end/block.
- Block: confirm; server action; end session and prevent future pair/social/call/message.
- Add Friend: create idempotent request; state becomes Requested; does not auto-friend.
- Follow: one-way toggle; does not grant chat/call.
- Participant profile: safe profile preview; no private fields.
- Connection/error: reconnect status; retry or End; stale events ignored.
- On match arrival, both users automatically enter same session; no second accept button.
- No recording by default; disclose if a future feature changes this.

## S06 — Post-Match
- Add Friend/Requested/Friends state.
- Follow/Following.
- Continue Chat only if policy/session grants it; reuse canonical conversation.
- Next Match or Return Home.
- Report/Block remain accessible.
- Ended session never reconnects; nonfriend former match cannot private-call directly.

## S07 — Discover / People Search
- Search username/display name; safe filters; online only if presence privacy allows.
- Suggested/online cards use real profile/presence data; no fake seed users in production.
- Card tap opens Profile; Add Friend/Follow actions are explicit; Message/Video Call obey policy.
- Pagination, empty/no result, error/retry, rate limit.
- No exact location, phone or email exposure.

## S08 — Public Profile
- Avatar, display name, username, bio, languages, interests, approved media/intro video, privacy-safe stats.
- Relationship state/action area: Add Friend/Requested/Accept/Friends; Follow/Following; Message; Video Call; Report; Block.
- Intro video is playback/preview only, never live-call initiation.
- Video Call → preflight privacy/block/availability → call request; receiver must Accept.
- Message → permission check; creates/opens canonical conversation only if authorized.
- Profile counts: Friends, Followers, Following; Fans is alias of Followers, no duplicate count.
- Private fields never render.

## S09 — Edit Profile / Media
- Edit display name, username, bio, languages/interests, avatar, gallery, intro video, visibility.
- Save: validate format/size/moderation, upload securely, update server, refresh profile.
- Cancel: discard confirmation if dirty.
- Remove media: confirmation, storage cleanup policy, server state update.
- Intro video upload: length/size/format limits, moderation/consent; preview before publish.
- Failure: preserve draft, retry; no broken public media.

## S10 — Connections (one unified Social category)
**Tabs:** Friends | Requests | Followers | Following | Discover People.
- Friends: open profile, Message, Call (request only), Remove Friend (confirm).
- Requests: Received (Accept/Decline); Sent (Cancel); duplicate/reciprocal requests resolve atomically.
- Followers: list + profile; optional remove follower if supported, privacy action.
- Following: list + Unfollow.
- Discover People: search/suggestions/online privacy-aware cards.
- Follow/Unfollow is one-way; Friendship is mutual. They can coexist without duplicate cards.
- Fans is legacy label only; redirects/aliases to Followers.
- Each tab has loading, empty, error/retry, offline, pagination and refresh.
- Follow/Friend never automatically creates chat or connects a call.

## S11 — Chat Inbox
- Tabs/filters: All, Unread, Friends, Match History, Archived (if implemented).
- Search conversation; unread badge; last message/time; safe participant info.
- Open thread; mark read only on acknowledgment; archive locally/server policy.
- New chat only from authorized profile/action/match conversation; Follow or request alone cannot create empty chat.
- Loading, no chats, offline, error/retry; pagination.

## S12 — Chat Thread
- Text send, emoji, approved image/media attachment, reply (if included), edit/delete own message per policy, report/block, typing indicator, delivered/read state, search in thread (if included).
- Send: validate, optimistic UI with rollback, idempotency; retry only safe.
- Attach: permission, type/size scan, upload, send reference; reject unsafe media.
- Message actions menu: copy, report, delete/edit as permitted; destructive confirmation.
- Call buttons: audio/video request only after eligibility/privacy/block checks; no direct connect.
- Match chat and later friend chat reuse one canonical thread.
- Realtime disconnect/reconnect, duplicate/out-of-order event handling, pagination and keyboard/insets.
- Translation: V2 opt-in; original retained/displayed clearly, translation labeled; never fake.

## S13 — Private Call (outgoing/incoming/active/history)
**Outgoing:** choose Audio/Video → preflight → ringing → cancel/timeout/busy/declined/accepted.
**Incoming:** caller identity and call type → Accept/Decline; Accept grants media session; Decline/timeout closes request.
**Active:** remote/local media, mic, camera, speaker, flip camera, End, connection quality/reconnect.
**History:** missed/declined/ended metadata; no recording content.
- Friends status alone never connects.
- Privacy: Friends/Nobody or policy-defined options; block and availability enforced.
- WebRTC signaling, TURN credentials, network changes, permission denied, device busy and failed ICE paths handled.
- No false “connected” state before peer media/session confirmation.

## S14 — Notifications / Activity
- Friend requests, accepted requests, follows (configurable), incoming calls, missed calls, match/system/safety events.
- Open notification → authenticated, authorized exact target.
- Mark read/unread; preferences per category; push opt-in; deep-link fallback.
- No sensitive message/call content in lock-screen push by default.
- Notification delivery failure does not lose server inbox event.

## S15 — Settings / Privacy / Safety
- Account: logout, session/device controls if supported, account deletion request and confirmation.
- Privacy: profile visibility, discoverability, online visibility, DM policy, call policy, match availability.
- Safety: blocked list/unblock, report history/status if policy allows, community rules/help.
- Permissions: camera/mic explanation and OS settings link.
- Consent: AI/translation, media and data processing toggles with disclosure.
- Language, accessibility, theme, notifications.
- Every change server-validated and auditable; destructive actions confirm.

## S16 — Wallet / VIP / Coins / Gifts (V2 gated)
- Balance/ledger, plans, purchase, gift inventory/send, transaction history, rewards.
- Server calculates price/balance; idempotent ledger; payment webhook verification; refund/reversal.
- Payment pending/failed/success only after authoritative provider verification.
- Feature flags hide unavailable purchasing; never fake success or allow client balance mutation.

## S17 — Engagement (V2 gated)
- Achievements, streaks, referrals, missions/rewards.
- Server validates eligibility and claims; duplicate claim idempotent; anti-fraud/rate limits.
- Clear terms, expiry, progress and reward status; no deceptive guaranteed earnings.

## S18 — Help / Report / Support
- Help/FAQ, contact/support ticket, report user/content/session, appeal where available.
- Report category, evidence optional, submit confirmation, ticket status.
- Report never requires staying in unsafe call; Block/End remain immediate.
- Admin moderation event/audit created securely.

## S19 — Global overlays and shared components
- Incoming call overlay: Accept/Decline; no blocking safety controls.
- Friend request sheet: Accept/Decline/View.
- Permission rationale: Continue/Not now; OS permission only contextually.
- Confirmations: remove friend, unfollow, block, report, delete account/media.
- Toast/snackbar: noncritical; auto-dismiss; never used to represent unverified success.
- Offline/reconnect banner, loading skeleton, empty state, retry, rate-limit/error dialog.
- Back/navigation, deep links, keyboard, safe area, accessibility labels and focus order.

## D. Website/PWA — page-by-page contract

### Public pages
- Landing: product explanation, safe CTA to Google sign-in, feature sections, FAQ, trust/safety.
- How It Works: transparent matching/chat/call flow; no false speed/safety claims.
- Safety & Community Guidelines: rules, reporting, blocking, consent.
- Privacy Policy, Terms, Cookie/data disclosures, contact/support.
- SEO metadata, canonical URLs, sitemap/robots, social preview, responsive and accessible layout.
- Download/install PWA, offline shell (never offline matching/calling).

### Authenticated web pages
- Google-only auth and resumable onboarding.
- Home/dashboard, Discover/Search, Profile/View/Edit, Connections tabs.
- Match lobby and manual filter page; active video room (remote stage + local preview + chat sidebar + controls).
- Inbox/thread, incoming/outgoing calls, call history.
- Notifications, Settings/Privacy/Safety, Help/Report.
- Wallet/VIP/engagement only when flags/integrations are live.
- Desktop keyboard shortcuts must not accidentally End/Block/Call; mobile browser permission handling and viewport adaptation.
- Same backend permissions, data and relationship semantics as Android; no separate web-only truth.

## E. Admin/Ops Console — pages and actions

### Admin authentication/authorization
- Staff-only identity and RBAC; least privilege; MFA/strong policy as available; every privileged action audited.
- Roles: support, moderator, operations, finance, content admin, super-admin; role permissions documented.
- No ordinary admin access to private call media; private content access is restricted, justified and audited.

### Dashboard
- System health, active sessions/queue metrics, errors, report backlog, notification/payment status, release/flag state.
- Metrics aggregate by default; no unnecessary personal data.

### User management
- Search by safe identifiers; profile/account status, verification/age eligibility status (avoid exposing DOB), suspension/ban/unban with reason and duration.
- Actions confirmation, permission check, audit entry, user notification where appropriate.

### Moderation
- Report queue, priority/severity, evidence metadata, review, action (warn/restrict/suspend/ban), appeal/resolve.
- Block/report abuse detection, repeat offenders, reviewer notes, audit.
- Strict evidence retention/access policy; no indiscriminate media surveillance.

### Match & Media Ops
- Queue health, match latency, pairing failures, session state, WebRTC/TURN health, aggregate quality metrics.
- Troubleshoot by session ID and authorized metadata; never fabricate match/user.
- Safe kill-switch/feature flags and incident procedures.

### CMS / Feature flags
- FAQ, community/safety content, notices, campaigns.
- Feature flags, rollout percentages, environment controls, emergency disable.
- Preview/publish workflow and audit.

### Monetization / Finance (V2)
- Plans/catalog, transactions, webhook state, refunds/reversals, fraud signals, reconciliation.
- Least-privilege finance role; no manual balance edits without ledger/audit reason.

### Analytics / Support / Audit
- Funnel, retention, reliability, safety trends, feature usage with privacy limits.
- Support tickets, escalation, user communication templates.
- Audit search/export under permission and retention controls; immutable/append-only where feasible.

## F. Shared backend domains and contract ownership
- Identity/auth/account lifecycle.
- Profiles/media/privacy.
- Presence.
- Connections: friend_requests, friendships, follows, blocks.
- Discovery/search.
- Match queue/sessions/preferences/eligibility.
- Chat/conversations/members/messages/attachments.
- Calls/signaling/ICE/TURN metadata.
- Notifications/preferences/devices.
- Reports/moderation/actions/audit.
- Feature flags/config/CMS.
- Wallet/ledger/payments/gifts/rewards (V2).
- Analytics/observability/support.

Every mutation: authenticated actor + authorization + validation + idempotency + rate limit + structured result + audit/analytics as appropriate. RLS and server-side enforcement are required; client checks alone are insufficient.

## G. Button/action acceptance checklist (applies everywhere)
For every control record:
1. Label and purpose.
2. Visibility/enable preconditions.
3. Loading/disabled behavior and duplicate tap protection.
4. Exact mutation/API/event.
5. Server authorization and idempotency.
6. Success state based on authoritative response.
7. Failure message, retry and rollback.
8. Analytics/audit event (privacy-minimized).
9. Accessibility/focus/keyboard behavior.
10. Unit/integration/E2E test.

No generic “button done” claim without evidence.

## H. Launch sequence — do not drift

### Gate 0: Product lock
- V4 hard locks + this review + roadmap are consistent.
- Changes require explicit decision; no spontaneous feature additions.

### Gate 1: Repository & CI foundation
- Audit code/architecture, environment secrets, lint/analyze/test/build workflows, dependency/security scanning.
- Resolve current scaffold inconsistencies before adding more UI.

### Gate 2: Auth + onboarding + profile
- Google sign-in, account lifecycle, onboarding, privacy/consent, media and profile fully integrated and tested.

### Gate 3: Connections + discovery + presence
- One Connections UI/service; Friends/Requests/Followers/Following/Discover.
- Search, profile actions, presence and privacy consistency; RLS and race tests.

### Gate 4: Chat
- Canonical thread, realtime, attachments, typing/read state, notifications, safety/block.

### Gate 5: Match engine + video
- Instant, Next, Manual filters; atomic queue; session events; WebRTC/TURN; permissions/reconnect; safety controls; two-user/device/network tests.

### Gate 6: Private calls + notifications
- Request/accept lifecycle; incoming overlay; push/inbox; history; privacy and block.

### Gate 7: Safety/Admin launch operations
- Reports, moderator queue, user action, audit, support, emergency flags and incident plan.

### Gate 8: Web/PWA parity
- Public pages and authenticated core flows; responsive, accessible, same backend and safety.

### Gate 9: Release readiness
- Automated tests + manual two-user/device tests, RLS/security review, abuse/rate limits, performance/load, backup/restore, monitoring, support/legal/privacy review, rollback.
- Final user review/approval → controlled production rollout → store/public launch.

### After launch
- V2: translation/AI, smart matching, VIP/coins/gifts/rewards/ads/referrals/creator features, richer CMS/analytics.
- V3: scaling, personalization, global expansion, ecosystem and advanced safety.
- Roll out behind flags; measure quality/safety; never compromise P0.

## I. Definition of Done
- **SPECIFIED:** written contract.
- **IN_PROGRESS:** work active.
- **IMPLEMENTED:** code exists.
- **INTEGRATED:** connected across required services/surfaces.
- **VERIFIED:** tests/evidence recorded.
- **RELEASED:** approved deployment.
Each feature must be tracked with status, owner, dependencies, evidence, blockers and next action. Current status must be updated from repository/test evidence, not optimism.

## J. Final focus lock
**Build, integrate, test and launch a reliable VibeMingle Core first.** Do not drift into nonessential V2/V3 additions while P0 is incomplete. Keep all scope preserved in V4, but prioritize real user flows, safety, security and launch quality over feature count.
