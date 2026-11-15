# VibeMingle V4 — Final Updated Screen-by-Screen & Button Blueprint
Status: PRODUCT SPECIFICATION / REVIEW DRAFT. This is not proof of implementation, integration, build, or testing. V1/V2/V3/V4 and prior locked decisions remain preserved; this document consolidates and extends them.

## Global product invariants
- Google-only sign-in; one Continue with Google entry for new and returning accounts.
- Android + responsive Website/PWA + Admin/Ops.
- Connections hub: Friends, Requests (sent/received), Followers (Fans alias), Following, Discover People. Friend is mutual; Follow is one-way. Follow alone grants neither chat nor calls.
- Match conversation is canonical and reused after friendship; never create duplicate chat.
- Stranger video is adult-only and consent/eligibility validated. Pairing is server atomic; one active session/user; block-aware; no silent filter broadening.
- Matching modes: Instant Random, Random Switch/Next, Manual Stranger Search with approved adult age/gender/language/interests filters and preview.
- Next/Switch only after 15 seconds; End/Report/Block/Mute/Camera Off immediate.
- Private calls always Request → recipient Accept → authorized call room/token → join. Friendship is not call consent.
- Live translation (speech detection, translated/original captions, translation audio) is ON by default where supported and consented; user can disable. Admin can stop/hide/restrict/restore service. No consent/security override.
- Chat E2EE; no universal Admin decrypt key, covert monitoring, or blanket ZIP backup. Only selected/reported/authorized case evidence can be exported, audited, encrypted and retained for a limited period.
- Sexual exploitation/grooming indicators are excluded from general AI monitoring per owner instruction. Other specified abuse/safety categories remain.
- AI signals are context-sensitive and not proof; human review, appeals, false-positive handling.
- IP location is approximate; GPS is never exposed to strangers and is permission/need/consent-based. Security access is least-privilege and audited.
- No hidden camera/mic, silent recording, or safety-exit delay.
- Admin no-code controls can mitigate/rollback configuration; code defects require code changes and verified release.
- Admin toggles cannot disable authentication, encryption, consent, Report/Block or emergency safety exits.
- Status vocabulary: SPECIFIED / IN_PROGRESS / IMPLEMENTED / INTEGRATED / VERIFIED / RELEASED. Docs do not equal implementation.

## Universal screen/button contract
Every interactive control: label → preconditions → enabled/disabled state → frontend handler → authorized API/domain operation → persistence/transaction → realtime event → success UI/navigation → error/retry/rollback → audit/analytics (if appropriate) → security test. Every route/deep link rechecks auth, permissions, block state, expiry and target existence.

# ANDROID / WEB USER SCREENS

## S00 Splash / Bootstrap
Controls: logo/loading indicator (no user action); Retry; Update; Help/Exit when available.
- Bootstrap: initialize app, load safe remote config, validate minimum version, restore secure session, fetch account/consent/profile state, resolve route.
- Routes: signed out→S01; onboarding incomplete→S02; consent pending→S02/consent; profile incomplete→S08; eligible→S03; suspended/maintenance/update→dedicated status screen.
- Retry repeats safe/idempotent reads; offline shows cached-safe status and retry; never bypasses auth/age/consent.
- Admin: crash/boot/version/network aggregates, no tokens or private message content.

## S01 Google Authentication
Buttons: Continue with Google; Terms; Privacy; Help; Cancel/back.
- Google OAuth state/nonce/PKCE; backend verifies identity/token; creates/refreshes session; routes new account→S02, existing→state resolver.
- Cancel returns safely; failure shows stable error + retry; no passwords or alternate OAuth.
- Security: server-side identity verification, token protection, replay prevention, rate limits, logout/session revocation.

## S02 Welcome / Onboarding / Age / Consent
Controls: Next; Back; language selector; adult eligibility confirmation/age assurance; Terms/Privacy checkboxes; stranger video consent; optional AI/translation consent; profile setup; complete.
- Each required consent is versioned and stored with timestamp/purpose; optional AI consent independently revocable.
- Next disabled until required items valid; Back preserves safe local progress; Complete validates server-side and routes S08/S03.
- Do not rely solely on client age value for adult-only stranger video; policy-approved age assurance and eligibility server check.

## S03 Home
Controls: Match Now; Discover; Connections; Inbox; Calls; Notifications; Profile/avatar; Settings; Wallet; Rewards; Help; announcements.
- Match Now→S04; Discover→S09; Connections→S10; Inbox→S11; Calls→S13; Notifications→S14; Profile→S07; Settings→S15; Wallet→S17; Rewards→S18; Help→S20.
- Realtime badges: unread, requests, calls, safety/system notices. Tapping badge opens authorized destination.
- Loading skeleton; empty onboarding hints; offline disables network actions but preserves safe navigation.

## S04 Matching Lobby / Manual Filter / Preview
Controls: Instant Random; Random Switch/Next; Manual Search; filter category selectors (approved age/gender/language/interests); Preview; Apply; Reset; Start; Cancel; Help.
- Preview explains selected criteria, eligibility, available filters and camera/mic readiness; no guarantee of peer or identity.
- Apply saves validated preferences; Start calls server queue operation with idempotency key; Cancel removes queue safely.
- Server validates adult eligibility, filter allowlist, block list, consent, rate limits and one-active-session rule.
- No compatible user: honest waiting state; Wait / Edit Filters / Cancel. Never silently widen filters.
- Pairing atomic; stale queue cleanup; fair queue/cooldown. <1s pairing and 1–2s Next are targets only if compatible peer waiting.
- Next disabled until session elapsed≥15s; safety exits always active.

## S05 Stranger Video Call
Controls: mic toggle; camera toggle; camera switch; speaker/audio route; captions toggle; source/target language; translation audio toggle; translation volume; original audio mode; caption size/position; Next; End; Report; Block; Help/diagnostics.
- Pair event→authorized call/session UI; WebRTC signaling, ICE/STUN/TURN or approved media provider; connection states connecting/connected/reconnecting/failed/ended.
- Translation is default ON where supported/consented; original audio fallback always available. Caption/translation controls independently toggle; provider/network failure does not end base call.
- Next only after 15 seconds; End/Report/Block/Mute/Camera Off immediate. Report opens S20; Block confirms then terminates session and denies future contact/matches.
- Handle permission denied, device unavailable, background/foreground, network switch, ICE failure, reconnect timeout, remote leave, app crash recovery. No recording by default.
- Admin aggregates connection/join latency, ICE/TURN, jitter/loss/freeze, provider/region and error IDs; no private media.

## S06 Post-Match
Buttons: Add Friend; Follow; Continue Chat; Next Match (15s rule where active); Home; Report; Block; feedback.
- Add Friend→request state; recipient accepts in S10; Follow is separate. Continue Chat opens canonical thread S12. Next starts new queue session only after allowed timing.
- End current media before next session; no duplicate thread; block/report terminate and enforce immediately.

## S07 Public Profile
Controls: avatar/media preview; Friend/Request/Accept/Remove; Follow/Unfollow; Message; Audio Call Request; Video Call Request; Report; Block; Share; More.
- Profile visibility respects privacy. Message only if policy/relationship allows; call buttons create request, never direct join.
- Accept/Remove/Follow changes server-authoritative relationship and realtime updates.
- Block overrides all interactions; share link reveals only public profile fields.

## S08 Edit Profile / Media
Controls: avatar upload/remove; name/username; bio; language; interests; visibility; preview; Save; Cancel.
- Upload signed/authorized URL→file validation, size/type limits, malware scanning, EXIF/location metadata removal, moderation as required→publish.
- Save validates uniqueness/policy; optimistic UI rolls back on error; cancel discards unsaved changes.
- Admin can moderate reported profile/media; cannot impersonate without audited privileged workflow.

## S09 Discover People
Controls: search; approved filters; sort; result cards; profile; Follow; Friend Request; pagination/load more; clear.
- Server applies visibility, age/privacy, block and rate-limit filters. No hidden private fields. Search errors retry; empty state suggests safe filter adjustment.
- Each card actions follow S07 relationship/call rules.

## S10 Connections Hub
Tabs: Friends; Requests (Received/Sent); Followers (Fans alias); Following; Discover People.
Buttons: Accept; Reject; Cancel sent request; Remove Friend; Follow/Unfollow; Search; Profile; Message where allowed; Report; Block.
- Mutual friend state only after accept; Follow never creates friendship or call permission. Duplicate/racing requests idempotent; realtime updates all tabs/badges.
- Block cancels pending relationships/contact paths per policy.

## S11 Inbox / Conversation List
Controls: search; filter/unread; conversation row; mute; archive; pin; new conversation (allowed); refresh/pagination.
- Row shows safe preview, unread count, time, privacy-aware presence. Open→S12 after authorization/block checks.
- No plaintext E2EE indexing server-side; device-local search where possible. Archive/mute affects only user view/preferences.

## S12 Advanced E2EE Chat
Header buttons: profile; Audio Call Request; Video Call Request; search; mute; more/report/block.
Composer: text; emoji; voice record/send; image/file/video attach; preview; send; reply; reaction; edit (time-limited); delete-for-me; policy-based delete-for-everyone; forward (controlled); pin; report message.
- Send: encrypt on device→authorized conversation membership/block/limits check→store ciphertext→realtime ciphertext event→recipient decrypt→delivery/read receipt (user privacy settings)→ack. Retry uses idempotency key.
- Typing/presence are ephemeral, authorized, privacy controlled, rate-limited; no message content in logs/analytics.
- Attachment pipeline: signed upload, size/type allowlist, malware scan, metadata stripping, access-bound storage, encrypted sharing design and expiry.
- Local search over decrypted messages; no server plaintext search. Voice note encryption and playback controls.
- AI safety: transparent opt-in/on-device or selected reported content; no universal server plaintext inspection. Keyword/context signals are not automatic guilt; reported evidence review with human/appeal.
- Call button→request/accept S13; never instant private call. Block immediately stops message/call delivery.

## S13 Calls Hub / Incoming & Outgoing Calls
Tabs: Incoming; Outgoing; Active; Recent.
Buttons: Accept; Reject; Cancel; Call back/request; End; audio/video controls; reconnect; Report; Block.
- Request→ringing→accept→authorization and room/token issuance→join→connected/reconnecting→ended/failed. Busy/timeout/reject/cancel are explicit states.
- Accept revalidates requester/recipient, privacy, block, availability, consent and request expiry. No rejoin old stranger session/direct-call.
- Active private call uses S05 media/translation controls. Return to originating chat/profile after end.

## S14 Notifications
Rows: friend request; message; call; match; gifts/rewards; safety; system.
Buttons: open; mark read; mark all read; preferences.
- Deep link revalidates authentication, target, expiry, block and permission; stale link routes safe fallback. Push payload avoids sensitive plaintext.

## S15 Settings / Privacy / Security
Sections/buttons: Account; Privacy; Safety; Notifications; Audio/Video; Matching; Language/Translation; Accessibility; AI consent; Devices/Sessions; Data export; Delete account; Logout; Logout all; Help/Legal.
- Save settings with validation/version; translation and AI controls respect service availability/consent. Device revoke invalidates session; account deletion uses confirmation/step-up and retention/legal workflow.
- User controls receipts/presence/visibility/retention where policy allows.

## S16 Safety Center / Report / Block / Help
Controls: Report user; report selected message; category; description; attach selected evidence; submit; case ID/status; appeal; block/unblock; FAQ; contact support; diagnostics.
- Report only sends selected user-approved evidence plus required context; encrypted case vault, role-based access, audit, retention.
- Block immediate local UX + server enforcement across match/chat/call/friend/follow; active call ends. End/Report/Block never wait for 15 seconds.
- Categories include harassment, threats, blackmail/extortion, scams/spam, self-harm concern, credible violent/terror threat and other policy categories; grooming/sexual-exploitation indicators excluded from general AI monitoring.
- AI risk score is triage only; human review, appeal and false-positive handling.

## S17 Wallet / VIP / Coins / Gifts / Payments
Controls: balance; VIP plans; buy coins; send gift; transaction history; restore purchase; support/refund.
- Provider checkout→verified server receipt/webhook→idempotent ledger transaction→realtime balance/receipt. Client never mints coins.
- Signed webhooks, fraud/rate limits, refund/chargeback reconciliation, clear pricing/consent. No payment test is claimed.

## S18 Rewards / Referrals / Engagement
Controls: missions; progress; claim; referral code/link; share; history; streak/campaign.
- Server validates eligibility, anti-abuse and claim idempotency; no client reward mint. Fraud patterns sent to risk queue.

## S19 Media Viewer / Attachments / Profile Intro Preview
Controls: play/pause; mute; seek; close; report; download only if policy allows.
- Profile intro is preview only; never auto-joins a call. Media access signed/authorized, expiry and block checks.

## S20 Global Dialogs / Errors / Overlays
Dialogs: confirm; permission; offline; retry; rate limit; call conflict; filter unavailable; block/report; maintenance; update; attachment warning; translation failure.
- Accessible focus/keyboard/back; clear safe actions; no duplicate submit; correlation ID for support; no secrets or plaintext in error logs.

# WEBSITE / PWA
W00 Landing: Continue with Google; feature/FAQ/legal; install PWA; support. No private data before auth.
W01 Auth: Google OAuth and secure redirect handling.
W02 Onboarding: same age/consent/profile gates as Android.
W03 Home: same routes/badges/features; responsive navigation.
W04 Match/Filters: same filter preview, apply, queue, 15s Next and immediate safety exits.
W05 Video: WebRTC/media provider, permissions, translation/captions/audio, reconnect and report/block.
W06 Profile/Edit: same privacy, friend/follow and call-request rules.
W07 Connections/Discover: same mutual friend/follow semantics and block enforcement.
W08 Inbox/Chat: same E2EE protocol, encrypted media, receipts, translation and call requests; browser key security threat model.
W09 Calls: same request/accept lifecycle and controls.
W10 Notifications: authorized deep links.
W11 Settings: privacy, consent, devices, translation and data lifecycle.
W12 Wallet/VIP; W13 Rewards; W14 Help/Safety. Each route uses same backend authorization, error contracts, analytics minimization and feature flags. Web parity must be verified, not assumed.

# ADMIN / OPS SCREENS

## A00 Admin Login
Google/approved admin identity, MFA/step-up, device/session security; no public user role escalation.

## A01 Live Overview
Metrics: active users, match queue, calls, chat delivery, translation health, incidents, errors, service status. Aggregates by default; no private content.

## A02 Error & Glitch Center
Fields: error ID, severity, module/route/platform, frequency, correlation, impact, safe stack/trace, owner, status.
Actions: acknowledge; assign; incident; annotate; resolve/reopen; export sanitized logs. Code fix requires code/release; dashboard can mitigate only.

## A03 Match Operations
Queue health, wait percentiles, pairing errors, stale queue, cooldown and service switch/rollback. No manual pairing that bypasses consent/block.

## A04 Call Diagnostics
Join success, setup latency, ICE/TURN, jitter/loss/freeze, reconnect, region/provider. Actions: incident; provider config rollout; disable faulty optional service; never access call media without lawful user-reported evidence.

## A05 User & Account Operations
Search by authorized identifiers; account state; suspend/restore; session revoke; appeal; safety notes. Every action reason-coded and audited; least privilege.

## A06 Moderation / AI Safety
Risk queue; category/severity; evidence source; confidence/context; human review; action; appeal; false positive; escalation. AI cannot be sole basis for irreversible punishment.

## A07 Translation Service Control
Default ON where available; ON/OFF; hide UI; emergency stop; languages/provider; rollout; health; latency/errors; restore/rollback. Respect user consent, original audio fallback, audit every config change.

## A08 Chat / E2EE Health
Delivery/realtime metrics, ciphertext pipeline health, attachment scan status, report volume, protocol/version health. No Admin universal decrypt or private chat browsing.

## A09 Evidence Vault
Case-scoped user-submitted evidence only; ZIP export; integrity hash/manifest; encryption; retention expiry; access approval; audit; revoke/export history. No blanket chat backup.

## A10 Security Center
Login anomaly, IP/device/session signals, rate-limit/WAF/API abuse, secret/dependency alerts, vulnerability/incident status, session revocation. IP geolocation approximate; GPS access prohibited unless justified/consented and separately governed.

## A11 Feature Flags / Remote Config
Service ON/OFF, hide, staged rollout, cohort/region, validate, preview, approval where risky, propagation status, rollback. Cannot weaken auth/E2EE/consent/safety.

## A12 CMS / Announcements
Content create/edit/preview/schedule/publish/rollback; role-based review; safe rendering.

## A13 Payments / Wallet / VIP
Ledger reconciliation, provider webhook status, refunds/chargebacks, fraud queue, audit; no direct client balance edits.

## A14 Rewards / Referrals
Campaign configuration, eligibility, fraud review, claim reconciliation, rollout/rollback.

## A15 Analytics
Privacy-minimized product metrics, funnels, reliability, retention; no plaintext content or unnecessary personal data.

## A16 Support
Ticket, assignment, SLA, sanitized diagnostics, escalation and user response. No privileged impersonation without audited approved process.

## A17 Admin Roles / Audit
Least-privilege roles, separation of duties, MFA, approvals, immutable audit, break-glass and review.

## A18 Incident / Release / Environment
Incident commander, timeline, impact, mitigation, rollback, postmortem; staging/prod separation; release approvals and status. Production deployment/store launch requires owner approval.

# BACKEND / REALTIME CONTRACTS (illustrative; schemas versioned)
- Auth/account: verified Google identity, session lifecycle, consent versions, age eligibility.
- Match: queue join/cancel/status, atomic pair, next, session end; idempotency and block/eligibility checks.
- Call: request/accept/reject/cancel/expire/join token/end; private and stranger session authorization.
- Chat: ciphertext send, receipts, typing ephemeral channel, reactions/edit/delete, attachment grants, report selected content; strict conversation membership.
- Translation: consent/session enable, language selection, captions/audio streams only to call participants, provider health and fallback.
- Safety: report/case/appeal/block, evidence export authorization, retention jobs.
- Admin: RBAC, config versions, rollout, audit, incident, restore.
- All operations: authn/authz, schema validation, RLS, rate limits, idempotency, transactions, stable error codes, correlation IDs, telemetry redaction.

## Navigation/redirect invariants
- Deep link always resolves through auth→consent/eligibility→target authorization→block/expiry check.
- Match end clears active media and routes to post-match; Next creates new queue attempt; report/block exits to safety confirmation/state.
- Private call request always returns to source context; accept opens call; reject/timeout returns to chat/profile with state.
- Call end returns to originating context; notifications cannot bypass authorization.
- Block invalidates pending friend/follow/contact/call/match paths according to policy.
- No orphan routes, duplicate engines, or dead buttons.

## RED-TEAM / ACCEPTANCE CHECKLIST
- Google OAuth state/nonce/PKCE, session theft/revocation, account takeover.
- RLS, API authorization, realtime channel isolation, IDOR, rate limits, replay/idempotency, SQL injection/XSS/CSRF, upload malware, signed webhooks.
- E2EE independent threat/protocol review; prove Admin cannot decrypt normal private chats.
- Match race/duplicate pairing, queue poisoning, filter bypass, block evasion, 15s timing and immediate safety exit.
- Call spoofing, unauthorized room token, accept race, TURN credential leakage, reconnect/network/device permission cases.
- Chat delivery duplication, offline retry, attachment authorization, receipts privacy, local key compromise handling.
- Translation consent, provider outage, caption leakage across calls, language fallback and user opt-out.
- Report/evidence scope, ZIP integrity, access approval, retention/deletion, audit and false-positive appeals.
- Admin privilege escalation, malicious config, emergency stop/restore, rollout/rollback and audit tampering.
- Android/browser two-user and multi-network E2E; accessibility, performance, load, backup/restore and incident drills.
- Close critical/high findings before release; owner reviews scope and release candidate.

## Completion status
This blueprint is **specified**. It is not evidence that screens, buttons, APIs, database, realtime, AI, translation, Admin, builds or tests are implemented/verified. Actual implementation must be tracked by phase with code, test output, staging evidence and review. No production release without owner approval.
