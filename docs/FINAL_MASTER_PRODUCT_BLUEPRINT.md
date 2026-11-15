# VibeMingle — Final Master Product Blueprint (V1/V2/V3)
Updated: 2026-11-15
Repository: vanshiram-pixel/VibeMingle | Branch: feat/typing-presence
This document consolidates the locked product direction, prior feature discussions and the current matching/video/chat/translation decisions. It is the screen-by-screen product contract. It does NOT claim features are implemented merely because they are specified.

## 0. Product invariants / scope lock
- Surfaces: Android app, responsive website/PWA, full Admin/Ops console. Shared backend contracts, permissions and design language.
- Authentication: exactly one **Continue with Google** entry. First Google sign-in creates account and proceeds to onboarding; returning identity logs in. No separate email/password or alternate social login unless user explicitly changes scope.
- V1/V2/V3 are delivery tiers, not permission to omit integrations. Build complete vertical slices with real wiring; do not ship placeholder buttons or fake success.
- Safety exits (End, Report, Block, mute/camera off) are never blocked by a timer.
- Stranger matching: auto-pair and automatic call handoff; <1s target when compatible waiting peer exists; Next target 1–2s with peer; 15s Next lock; empty queue continues visibly until Cancel, not a 60–70s timeout.
- Never expose private phone/email/address or exact location. Do not record calls by default.
- Feature status labels: NOT STARTED → IN PROGRESS → IMPLEMENTED → INTEGRATED → VERIFIED → RELEASED. A doc, UI shell, migration or scaffold is not VERIFIED.
- Production deploy, store publishing, public launch, PR merge require user notice/approval.

## 1. Global app shell and navigation
### Android/Web user shell
- App launch: splash/loading → session restore → account/auth gate or home.
- Main navigation (adaptive bottom bar/rail): Home/Discover, Match, Friends, Messages, Notifications, Profile. Wallet/VIP and Settings accessible from profile/menu and contextual entry points.
- Global top-level: avatar/profile menu, search, notification badge, wallet/coin balance (only if enabled), help/safety, connectivity state.
- Common UI: loading skeleton, empty state, retry, offline banner, snackbar/toast, confirmation dialog, bottom sheet, tooltip, popover, permission explainer, deep-link router, keyboard/inset handling, RTL/LTR, text scaling, accessibility labels.
- Popup rules: transient toast/snackbar auto-hide; action sheets/dialogs dismiss by outside tap/back where safe; destructive actions require confirmation; call/match/safety overlays remain until explicit action/state resolution; unread badges clear only after read acknowledgment; no popup blocks End/Report/Block.
- Every route supports back navigation, safe area, loading/error/empty states and analytics; deep links verify auth + ownership before opening.

## 2. Screen inventory — user journey from first open to exit
### S00 Splash / session bootstrap
- Brand mark, version/build, progress; restore Supabase session, validate account/suspension, fetch config/feature flags.
- Actions: retry, offline guidance; route to S01 or S03/S04. No sensitive data shown.

### S01 Authentication
- One button: Continue with Google; loading, provider error, cancel, retry, network failure.
- Google OAuth callback validates state/nonce; backend upsert identity safely; account creation vs login decided server-side; secure token/session storage.
- Terms/privacy links, age-appropriate legal disclosure. No alternate auth button.

### S02 First-time onboarding (stepper; resumable)
1. Age/date eligibility and safety gate (policy-defined; adult stranger video flow excludes minors).
2. Terms, privacy, community rules and explicit consent (separate stranger matching, mic/camera, translation/AI processing).
3. Display name, unique username, avatar, bio, languages/interests (required/optional clearly marked).
4. Profile visibility, discoverability, online status, DM/call/match privacy.
5. Camera/mic permissions explained contextually (ask when needed, not blindly at startup).
6. Review/finish; create profile, settings and onboarding completion transactionally.
- Back/skip rules, validation, duplicate username suggestions, upload retry, save draft/resume, delete/cancel account route.
- Completion → S03 Home; incomplete users cannot enter restricted matching/calls.

### S03 Home / Discover
- Cards/sections: quick Start Matching, suggested people, online/friends, recent chats, invitations, feature announcements, optional daily engagement/rewards.
- Search users by username/name; filter/sort only supported settings; no exact location.
- Each person card: avatar, display name, username, verified/safety labels if warranted, online indicator privacy-aware; actions View Profile, Add Friend/Follow (depending relationship), Message/Call only when policy permits, hide/dismiss/report.
- Feed recommendation must explain controls: refresh, hide person, not interested, report; pagination and empty/loading states.
- Quick popup: match launch sheet (camera/mic permission + match consent state); quick chat/call only if allowed; toast for sent request/action.
- Connects profile/discovery/friend graph/presence/block/report/recommendation APIs and analytics events.

### S04 Stranger Matching lobby
- Clear Start Matching button; camera preview/device check; language preference and optional V2 filters; consent/safety reminder; online/queue status.
- Start → atomically queue; Cancel removes queue reservation; duplicate taps idempotent.
- Search screen: animation/status (“Searching…”), elapsed time, cancel, network status, no fake candidate identity.
- Matched → same authorized match/session ID; auto-open S05 call without second accept prompt.
- Error states: permissions denied, account restricted, busy in another call, stale queue, no network, service unavailable; actionable retry/Settings.
- Next flow returns to matching only for continuing user; counterpart’s opt-in respected; recent pair cooldown.

### S05 Stranger video-call / Match card (V1)
- Remote video primary stage; local preview corner movable/resizable; portrait video upper region.
- Bottom controls: mic, camera, flip, speaker/audio route, chat toggle, captions/translation controls, Next, End; overflow includes Report/Block and help.
- 15-second countdown displayed; Next disabled until zero, tooltip/explanation. End/Report/Block immediately available throughout.
- Next → end current session, remove pair, new queue attempt; show Connecting/Searching; target 1–2s only if compatible peer waiting. Empty pool remains search with Cancel.
- Text chat below video (peek/compact) and expandable bottom drawer; input/send, message list, scroll, new message indicator, delivery/retry; keyboard resizes video and drawer without covering safety controls.
- Translation subtitles positioned away from faces/control area; choose original/translated display, font size/background/position; no fake captions.
- State: reserved, connecting, active, reconnecting, peer left, ended, reported, blocked, failed. Handle camera/mic permission, network, app background, orientation and audio route.
- Session metadata shared with chat, signaling, translation, safety, analytics; never create a separate chat/call identity.
- After call: S06 summary/feedback (optional), safety/report, reconnect/Next/Return Home; session closure idempotent.

### S06 Post-match / call result
- Call duration/connection quality and optional “How was this match?” (skip, thumbs/quality reasons, language/connection feedback).
- Add friend/follow only if policy/consent permits; continue matching, open conversation if allowed, return home.
- Report/block controls and explanation; no forced rating or social contact.
- Record minimal outcome/feedback; deduplicate on session ID.

### S07 User profile (self/other)
- Self: avatar, display name, username, bio, languages/interests, joined date (privacy configurable), friends/followers counts if enabled, achievements/streaks, profile preview.
- Actions: Edit, share profile link, privacy, avatar upload/crop/remove, username validation; other profile: Add/Accept/Remove friend, Follow/Unfollow, Message, audio/video call request (authorized), Gift (wallet enabled), Report, Block, Hide.
- Profile action availability is server-policy driven; blocked/private/suspended states show safe explanation.

### S08 Edit profile & media
- Text validation, character limits, username availability debounce, image crop/compress/format/size checks, upload progress/cancel/retry, content moderation, save/discard confirmation.
- Storage bucket signed access; no unsafe arbitrary URL uploads.

### S09 Friends / Requests / Following
- Tabs: Friends, Incoming Requests, Sent Requests, Following/Followers if feature flag enabled.
- Row actions: accept/reject, cancel, remove, follow/unfollow, message, call (permission), mute/hide, block/report.
- Confirm destructive remove/block; optimistic UI with rollback; dedupe/rate limits; realtime request updates; empty and pagination states.

### S10 Messages inbox
- Search/filter (all/unread/friends), pinned/muted/archive optional; unread badges, last message/time, delivery state, online indicator privacy-aware.
- Actions: open thread, mark read, mute notifications, archive/delete conversation (retention semantics clearly explained), report/block, start authorized call.
- Inbox events, push deep links, pagination and local cache reconcile.

### S11 Private chat thread
- Header: participant profile/presence, audio/video call, safety menu.
- Message types: text; approved image/media; system call/match events; translation view (V2); reactions/reply optional; edit/delete own message with time/policy limits.
- Input: send, attachments, emoji, reply, optional translate, retry failed, draft preservation. Typing indicator, sent/delivered/read receipts; chronological pagination; realtime authorized channel.
- Message actions long-press popup: copy, reply, edit own, delete own, report, translate, react (if enabled); no unauthorized delete.
- Safety block ends future send/call/match; report captures message IDs/context with privacy.
- Schema/RLS/realtime consistent; no duplicate legacy repository as canonical.

### S12 Private audio/video call
- Call request/ringing, incoming call screen (caller identity, type, Accept/Decline), outgoing waiting/cancel.
- Accepted → connecting → connected; audio/video controls, duration, network quality, speaker, mute, camera, flip, minimize picture-in-picture (platform support), chat shortcut; End.
- Declined, missed, busy, offline, permission denied, timeout, reconnect, failed, ended all explicit.
- Call history/missed calls, callback only if allowed, report/block.
- Authenticated signaling, WebRTC/LiveKit decision and TURN credentials; participant authorization; call status server authoritative; push notification contains opaque call ID only.
- Match calls use same media/session engine but match-specific state/timer/Next policy.

### S13 Notifications center
- Tabs/all/unread; request/friend, message, incoming/missed call, match result, safety/account, wallet/gift, system.
- Tap deep-links to verified destination; mark read/unread, mark all read, delete/hide where appropriate; notification preference link.
- In-app + push (FCM Android, APNs where applicable, web push later); token rotation/revocation; delivery retries/dedupe; no private content in lock-screen payload unless opted in.

### S14 Notification & privacy settings
- Per-category toggles: messages, friend requests, calls, match, gifts/wallet, product; quiet hours, sound/vibration, push/in-app.
- Privacy: profile discoverability, online status, who can friend/message/call, match consent, language, blocked list, hide list, read receipts/typing visibility.
- Account: Google identity, active sessions, logout, delete account/data export where required; consent history, terms/privacy versions.
- Changes persist and are enforced server-side, not merely UI.

### S15 Wallet / Coins / VIP / Gifts (V2)
- Balance, ledger/history, earn/redeem rules, purchase packages, transaction pending/success/failure/refund.
- VIP plans, entitlement status/renew/cancel/manage; benefits clearly disclosed; restore purchase where platform supports.
- Gift catalog, gift preview, recipient, confirm, send animation, receipt, received gifts/inventory; idempotent spend, anti-fraud, no negative balance.
- Payments via approved provider/store, signed webhook verification, idempotency, refunds/chargebacks, audit; never trust client balance.
- Ads placements: consent/privacy-aware, frequency caps, no ads on safety/call-critical surfaces; admin controls and analytics; ad-free entitlement.
- No monetary promise/earnings misrepresentation; minors/region restrictions.

### S16 Engagement / activity
- Optional achievements, streaks, milestones, daily activity/rewards, profile badges, referrals/invite link, share cards.
- Activity feed/notifications: friend accepted, gift received, achievement unlocked, streak reminder, match feedback; opt-out and quiet hours.
- Rewards server calculated, rate limited and ledgered; anti-bot/fraud; no manipulative compulsory loops.
- Quick popup/toast, badge count, animation, hide/dismiss preferences and accessibility reduced-motion.

### S17 Help / Safety Center
- Community rules, safety tips, report flow, block/hide list, FAQ/contact/support tickets, account appeals.
- Report categories (harassment, sexual content, spam, impersonation, minor/safety, threats, other), target/session/message references, optional evidence upload with clear consent/retention.
- Confirmation + report ID; no promise of immediate resolution; user can end/block instantly.
- Emergency guidance appropriate to region; platform is not emergency service.

### S18 Search, global overlays and reusable components
- Search overlay: users/content only as authorized; debounced, recent search clear, safe results.
- Profile quick view, match-start modal, call incoming/outgoing overlay, permission education, gift selector, report/block confirmation, translation settings, network reconnect, session-expired, account restricted, maintenance, update-required.
- Popups: open/close/hide rules, outside tap/back behavior, focus trap on web dialogs, Escape, keyboard, screen reader semantics, stacking priority. Safety/call overlays cannot be hidden accidentally.
- Toast/snackbar types success/info/warning/error; auto-dismiss and accessible announcement; undo only for reversible action.
- Button contract: disabled/loading/error states; double-tap protection; action analytics; API idempotency; clear label and confirmation for irreversible actions.

## 3. Website / PWA
- Same auth, onboarding, profile, discovery, friends, inbox/thread, matching/call (browser permission/device compatibility), notifications, settings, wallet/VIP/gifts and help.
- Responsive layout: desktop sidebar, topbar, content, video/chat split view; mobile nav and drawer.
- Browser media permission, HTTPS, device selection, audio routing limitations, tab background/reconnect; feature fallback clearly explained.
- SEO/public pages only for public-safe content: landing, features, safety, privacy, terms, help, status; authenticated user data not indexable.
- Installability, web push consent, deep links, session expiration, keyboard shortcuts/accessibility.
- Shared API/data contracts; do not fork business rules across mobile/web.

## 4. Admin/Ops console — RBAC and screen map
Roles: super admin, operations, moderator, support, analyst, finance (least privilege; configurable). Require MFA/strong session, audit every sensitive action, reason and scoped access.
1. Admin login/SSO policy + MFA; session/device audit.
2. Dashboard: DAU/WAU/MAU, new users, retention, match queue/match success, call connection, chat delivery, reports, bans, revenue, latency/errors; privacy-safe aggregates.
3. Users: search by opaque ID/username, profile/account status, age/consent status, session list, risk flags; no secret/token exposure.
4. Moderation queue: reports, evidence access restricted, triage, assign, priority, notes, action, appeal, SLA and audit.
5. Actions: warn, content removal, temporary suspension, ban, unblock/restore, rate-limit; reason, duration, notify, appeal and immutable audit log. Block/report enforcement across match/chat/call.
6. Live operations: service health, queue depth, WebRTC/TURN/translation provider health, notification failures, incidents, maintenance banner; never spy on private call media.
7. Content/CMS: landing/announcement/help/community rules, localization, versioning, preview/publish/rollback.
8. Feature flags/experiments: gradual rollout, cohort, kill switch, config audit; safety-critical defaults cannot be remotely weakened.
9. Monetization: product/coin packages, VIP entitlements, gift catalog, ad inventory/placements/frequency, transactions/refunds/chargebacks, webhook failures; finance permission.
10. Notifications: templates, targeting consent-safe segments, scheduling, preview, delivery analytics, opt-out and rate limit.
11. Analytics: funnels, cohort retention, match/call/chat quality, revenue; aggregate/minimize personal data.
12. Support: ticket queue, account appeal, response templates, user history limited by role; secure escalation.
13. Settings: roles/permissions, staff accounts, audit logs, retention, data export/delete jobs, backup/restore status, incident logs.
14. Admin activity after action: success/failure, affected entity, reason, timestamp, actor, audit ID; irreversible actions require confirmation and sometimes dual approval.

## 5. Backend domain map and canonical wiring
- Identity/account: Supabase Auth Google OAuth, profiles, account lifecycle, age/consent, session revocation.
- Social graph: friends/requests/follow, privacy, blocks/mutes/hides.
- Presence: heartbeat/TTL, privacy-aware online state, busy/away/offline.
- Match service: queue, atomic reservation, session, cooldown, events, feedback.
- Call/media: call/match sessions, signaling authorization, LiveKit/WebRTC, TURN, device/network states.
- Messaging: conversations, messages, media storage, typing, receipts, realtime, translation metadata.
- Translation: consent/preferences, speech ingestion, STT/language detection, translation, subtitle/audio events, quotas, retention.
- Notification: in-app inbox, push tokens, provider delivery, preferences, deep links.
- Monetization: wallet ledger, payments/webhooks, entitlements, gifts, ads.
- Safety: reports, moderation cases, actions, appeals, risk/abuse limits, audit.
- Admin/CMS/analytics: RBAC, staff actions, config, aggregates, operational metrics.
- Infrastructure: Supabase/Postgres/RLS/storage/realtime/Edge Functions; Firebase FCM; LiveKit or authenticated WebRTC/TURN; AI provider via server; payment provider via signed webhook; CI/CD, secrets, observability, backups.
- All mutations server validated; RLS default-deny; service keys never in client; realtime channels authorize participants; transactions and idempotency for money/session operations.

## 6. Cross-cutting event & state contracts
- Typed event envelope: event_id, schema_version, entity/session ID, actor, authorized recipient, sequence, created_at, payload; dedupe and stale event handling.
- Client state: loading/ready/empty/error/offline; optimistic mutation rollback; retry/backoff; cancellation; lifecycle/background; no duplicate requests.
- Realtime event categories: presence, friend, chat, call, match, translation, notification, wallet, moderation/account status.
- Server owns authoritative state; UI derived from state; no client-side trust for eligibility, timer bypass, coins, entitlements, bans or read permissions.
- Observability: correlation ID, latency, error code, minimal metadata; redact PII/audio/video/tokens; alert thresholds and incident runbook.

## 7. Security, privacy, compliance and abuse
- Threat model: account takeover, OAuth replay, fake profiles, spam, bot matching, harassment, grooming/minor risk, call spam, message/media abuse, payment fraud, admin insider, RLS/realtime leakage, provider key leakage.
- Controls: age/consent gate, moderation, block/report propagation, rate limits, CAPTCHA/risk checks as needed, content validation, secure uploads, MFA admin, least privilege, secrets rotation, backups, audit, data retention/deletion, privacy notice, regional policy.
- User can leave any call instantly; no forced 15-second participation. Block applies immediately across all surfaces.
- Translation audio/text processing is opt-in and disclosed; retention/deletion policy; no recording by default.
- Accessibility: screen reader, contrast, font scale, reduced motion, captions, keyboard navigation, localization/RTL.

## 8. Testing and acceptance gates
- Unit: state machines, validators, matching eligibility, timer, idempotency, money ledger, permissions.
- SQL/RLS: own/participant/admin scopes, blocked pair rejection, unauthorized RPC, duplicate concurrent reservations, privacy.
- Widget/UI: every button, popup dismissal, keyboard, safe-area, empty/error/loading, deep link, route guard.
- Integration: Google new/existing user, onboarding resume, friend, message receipts/media, calls, match auto-handoff/Next, translation, push, wallet/webhooks, report/block/admin.
- E2E: at least two real accounts/devices and cross-network TURN; Android + supported browsers; app background/foreground, network switching, permission denial.
- Load/chaos: concurrent queue, race Next, stale heartbeat, reconnect, provider outage, notification retries, webhook replay.
- Security: dependency scan, secret scan, threat review, RLS review, admin audit, privacy deletion.
- Release: staging acceptance, crash/error/latency dashboards, backups/restore drill, rollback, support/moderation staffed, store/legal assets, user approval.
- Feature acceptance requires code + integration + test evidence + security review; production behavior cannot be claimed from local docs.

## 9. Delivery plan (dependency-aware, no skipped gates)
P00 Scope & contracts: this blueprint + canonical schemas/events/design system; reconcile legacy chat/call.
P01 repo/CI/environments: format/analyze/test, SQL lint, Android/web build, secrets and branch protection.
P02 Google auth/account lifecycle + onboarding.
P03 age/consent/privacy/deletion.
P04 profile/media.
P05 discovery/friends/presence/block primitives.
P06 stranger match queue/atomic RPC/Next/session handoff.
P07 integrated video UX + signaling + TURN/LiveKit, same call engine for private/match.
P08 chat/realtime/receipts/media/typing/edit/delete + in-call chat.
P09 safety/report/moderation/admin enforcement.
P10 notification delivery/preferences/deep links.
P11 voice/chat translation service and controls.
P12 engagement/achievements/referrals.
P13 wallet/VIP/coins/gifts/payments/ads.
P14 full Admin/Ops/CMS/analytics/support.
P15 responsive website/PWA + cross-platform feature parity.
P16 performance, security, privacy, accessibility, load/E2E and staging.
P17 release candidate, operational readiness, store/web launch (only after user approval).
V2/V3 continue with advanced matching, ranking, translation audio, global scaling/localization and ecosystem after launch core is verified; the complete scope is retained, not removed.

## 10. Repository status at blueprint creation (2026-11-15)
Evidence currently: Flutter shell; partial auth/session UI; profiles migration; friends/presence SQL+initial UI; chat SQL/repositories/basic thread; call session SQL/repository/incoming UI/WebRTC scaffold; notification preference schema; specifications.
Not evidenced as complete: verified Google OAuth config, onboarding/age/consent UI, production migrations/RLS tests, atomic stranger queue, integrated video/signaling/TURN, in-call chat, translation, complete safety/admin, push delivery, web, monetization, CI, build, staging E2E or release.
Overall integrated launch readiness remains rough 10–15%; not a certification or weighted metric.
PR #1 is draft/unmerged. No merge/deploy/launch without approval.

## 11. Definition of “nothing missing”
Every screen has route, entry/exit, visible controls, enabled/disabled rules, event/API, DB ownership, permission, loading/empty/error/offline, analytics, safety and tests.
Every button has: label → click/tap → precondition → state change → API/event → success UI → failure/rollback → audit/analytics (where appropriate).
Every backend operation has: auth, authorization/RLS, validation, idempotency, transaction/race strategy, rate limit, error contract, observability and tests.
Every integration has provider configuration, secrets server-side, consent, quotas, outage fallback and verified staging evidence.


## 12. Locked Stranger Match → Friend → Chat/Private Call flow
The permanent, detailed contract is in [docs/STRANGER_MATCH_FRIEND_FLOW.md](STRANGER_MATCH_FRIEND_FLOW.md). Key invariant: Match Add Friend sends a mutual request; Accept creates friendship; Follow remains independent; canonical match conversation is reused; private call after friendship still requires receiver Accept and privacy permission; former non-friend matches cannot direct-call/rejoin; Block overrides every relationship and contact path. This is specified, not yet implemented or runtime verified.
