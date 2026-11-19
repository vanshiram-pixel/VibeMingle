# VibeMingle — New Scope Decisions: Live Chat, Translation, Chatbot & Stranger Privacy
**Status:** scope amendment / owner review pending; not sealed until reviewed  
**Applies to:** V1–V4 unified blueprint, Android, Web/PWA, Admin/Ops

## 1. Relationship system change (supersedes earlier follow/follower sections)
- Remove Follow, Following, Followers and Fans as product features, tabs, APIs, tables, events, UI actions and admin workflows.
- Keep Friends (mutual), incoming/outgoing Friend Requests, Discover People, Block and Report.
- Audit existing follow-related code/schema/routes and either migrate safely or remove only after data migration/compatibility review. Do not silently drop user data.
- Update all screen specs, navigation, notifications, analytics, database, admin and tests. Remove stale references.

## 2. Stranger profile sharing and permanent mutual hide
- Stranger match participants must not share/copy/forward each other's profile link, profile ID, contact details or identifying profile data from stranger-session surfaces.
- Do not expose share-profile action in stranger video, stranger post-match or stranger-match chat. Profile cards are limited to approved non-identifying display data.
- If either participant blocks the other during/after a stranger interaction, immediately terminate the session and apply a server-authoritative mutual suppression: both users permanently stop seeing/discovering/matching each other, and no profile, chat, call, notification, search, recommendation or re-match route can reveal/reconnect them.
- Suppression is a distinct safety relation, stronger than ordinary block; define policy carefully and make it irreversible from ordinary user UI. Admin may investigate but cannot casually override; any exceptional remediation requires restricted, audited workflow and policy.
- Prevent bypass by alternate account/session, stale cache, direct URL, deep link, search, queue race or realtime event. Account-level abuse detection can flag evasion without claiming perfect identity linkage.
- Block must be available immediately in active session; server enforcement precedes client navigation/cleanup.

## 3. WhatsApp-style live chat UX
- Canonical Inbox and Chat Thread, not separate message systems.
- In-app floating/minimized chat window (corner dock) while navigating other app screens; one or more active threads subject to device/layout constraints.
- Floating chat shows avatar/name, unread count, latest messages, composer, send, close/minimize/expand; it must not cover safety/call controls or obstruct accessibility.
- Tap floating window → expand canonical thread; close/minimize does not delete conversation or stop server delivery.
- Mobile uses app-native overlay/bubble behavior; web/PWA uses responsive dock/panel. OS-level floating overlay outside app is not implied and requires separate platform permission/design.
- Messages, unread/read cursor, typing, delivery and reconnect are canonical server state; local UI state never substitutes for persisted messages.

## 4. In-call chat / shared media
- Active video/audio call can open a call-linked chat panel without leaving call. Text, emoji, image, file, document and video attachment sharing are supported subject to policy, limits, scanning and storage controls.
- In-call chat is linked to the authorized call participants/session; do not create an unauthorized group or expose content after session access is revoked.
- Layout: video remains primary; chat panel/drawer (or mobile sheet) opens/closes; unread indicator when collapsed; composer and attachment menu; sent/failed status.
- Attachment lifecycle: pick/capture → client size/type checks → authenticated upload to private quarantine → server malware/content scan and media moderation → safe processing → authorized private object → message reference → realtime recipient delivery → signed/authorized download. Rejected files never become downloadable.
- Supported media limits, codecs, durations, size, retention and storage quotas must be centrally configured and visible to users. No unrestricted arbitrary file execution/preview.
- In-call chat should be lower priority than media: separate data channel or transport QoS where provider supports it; throttle/batch typing and chat events; prioritize audio/video packets and adaptation. Never promise chat can never affect media; load/network tests and adaptive degradation are required.
- Degrade gracefully: under congestion, pause large uploads/preview, throttle nonessential chat events and show upload pending; preserve call audio/video priority and never silently lose sent messages.

## 5. Real-time voice translation (language menu)
- Language menu lists supported input/source language (Auto Detect only if reliable) and output/translated language; user can change preferences during call.
- Voice translation is opt-in per user and per session; disclose speech processing/provider, data retention, limitations and consent withdrawal.
- Pipeline: microphone audio → authorized secure speech processing/stream → source-language detection/transcription → translation → translated text captions and (if supported) synthesized translated audio → recipient's selected output.
- Modes: original audio; translated captions; translated audio; both captions + translated audio. Users can switch/disable at any time.
- Keep original audio available as fallback; indicate translated/synthetic audio clearly; do not replace speaker identity or imply perfect translation. Show “processing/unavailable” state.
- No language/provider credentials in clients. Provider calls server-side; minimize retention; delete transient audio/transcripts per policy.
- Controls: language selector, Auto Detect, captions on/off, translated audio on/off, original audio toggle, mute translation, consent/details, report translation issue.
- Failure: unsupported language, low confidence, network/provider outage, latency, consent absent, quota. Fall back to original call audio and optionally captions; never block core call.
- Admin sees aggregate provider latency/errors/abuse alerts, not private transcript/audio by default.

## 6. Chatbot
- AI Chatbot is a separate assistant conversation surface, accessible from a Chatbot entry in app navigation/help and contextual “Ask VibeMingle” affordances.
- It may answer product/help, explain settings, call/network troubleshooting, safety guidance and user-requested translation help. Clearly label AI.
- It cannot impersonate another user, auto-send personal messages, accept/reject calls, bypass consent/block/age gates, change wallet or moderation decisions, or execute high-risk admin actions.
- User chat content is not sent to AI unless user explicitly chooses “Ask AI about this”; disclose context scope and allow clear/cancel.
- Safety: prompt-injection isolation, tool allowlist, output moderation, rate limits, abuse handling, no secrets in prompts/logs, provider retention disclosure, user feedback/report.
- Admin chatbot configuration includes approved knowledge sources, versioning, evaluation, kill switch, usage/error/latency metrics; no unrestricted model/tool access.

## 7. Real-time security alerting and privacy boundary
- Private chats remain private; do not create blanket admin live-reading or surveillance access.
- Security alerts are based on security metadata and automated detections: malware/file scan, phishing/known malicious URL, spam bursts, account takeover signals, credential/token anomalies, abuse/report spikes, policy-defined high-risk indicators.
- Message/content inspection must be limited to explicitly disclosed, proportionate safety scanning (e.g., file malware scanning and link reputation) and applicable legal/policy basis. End-to-end encryption, if enabled, means server cannot silently inspect plaintext; client-side safety reports or user-submitted evidence are explicit and consent-aware. Do not claim both true E2EE and unrestricted server content inspection.
- Admin alert payload: severity, event type, pseudonymous user/session IDs, timestamp, risk score/reason, safe metadata, evidence access path only if policy-authorized, correlation ID, suggested runbook. Never expose encryption keys, auth tokens or unrestricted message history.
- Alert flow: detection → deduplicate/score → real-time Admin Incident Center alert → acknowledge/assign/escalate → restricted investigation → documented action → audit/appeal/retention.
- False-positive review, alert thresholds, rate limiting and least privilege required. Security alerts do not automatically mean account punishment; automated containment only for clearly defined high-confidence threats.
- Admin RBAC, MFA/step-up, immutable audit, break-glass access with justification and alert, separation of duties for severe actions.

## 8. Admin real-time controls
- Real-time alert center, crash/error explorer, call quality, upload scanning, abuse/report queue, account/session risk, provider health, feature flags and rollout/rollback.
- Safe remote configuration only: typed allowlist, schema validation, environment isolation, staged rollout, approval for high-impact settings, audit and rollback.
- Admin cannot edit arbitrary backend code, database rows or secrets from dashboard. “No coding” operational controls are safe controls/feature flags, not a promise that every defect can be repaired without engineering.
- Bug/glitch event: client/server telemetry → dedupe → incident ticket/alert → impact/release/route/correlation → owner/runbook → fix → deploy via CI/CD approval → verify and close. Remote kill switch can disable affected feature while fix is built.

## 9. Cross-screen updates required
Update S03 Home; S04 Match; S05 Stranger Video; S06 Post-Match; S07 Profile; S09 Connections; S10 Inbox; S11 Chat; S12 Calls; S13 Notifications; S14 Settings; S15 Wallet; S17 Safety; S18 Overlays; Web/PWA; Admin/Ops; API/data/event contracts; analytics; test matrix and migration plan.

## 10. Mandatory acceptance tests
- Follow/follower UI, API and schema references removed or migration disposition documented.
- Stranger profile share disabled on every route; link/ID leakage and direct/deep-link bypass tested.
- Block creates mutual permanent suppression and prevents search, matching, chat, call, notification and stale event access.
- Floating chat persists and reconciles across navigation, minimize/expand, offline and multi-device.
- In-call chat supports validated image/file/document/video and unauthorized access tests.
- Congestion tests confirm media priority and graceful upload/chat degradation.
- Voice translation consent, source/output languages, mode switches, original fallback, provider outage and privacy deletion tested.
- Chatbot privacy, prompt injection, tool allowlist, opt-in context and kill switch tested.
- Security alert delivery, deduplication, RBAC, false-positive handling and audit trail tested.
