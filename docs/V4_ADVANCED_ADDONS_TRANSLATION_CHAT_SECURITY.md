# VibeMingle V4 — Advanced Add-ons Integration (Scope Extension)

Status: **SPECIFIED / ADD-ON SCOPE**. This document extends, never replaces, the locked V1/V2/V3/V4 product scope. It is not implementation or test evidence.

## Scope preservation
- Preserve every previously locked feature and screen.
- Merge duplicates into canonical services; do not remove distinct capabilities.
- Integrate the add-ons across Android, Web/PWA, backend, realtime, and Admin/Ops.
- Sexual exploitation/grooming indicators are excluded from ordinary AI safety monitoring per product-owner instruction. Do not add a dedicated detector/alert category for that topic. Other lawful safety and abuse controls remain.
- No production deployment, public launch, or store release without owner approval.

## A. Matching filters and preview
Matching screen additions:
- Instant Random, Random Switch/Next, Manual Stranger Search remain.
- Manual filters: approved adult age range, language, gender preference where permitted, interests, and other policy-approved availability filters.
- Filter preview, apply/reset, saved preferences, eligibility explanation, camera/microphone readiness preview, and compatible-search status.
- Never silently broaden a filter. If no compatible peer exists, show waiting state and explicit user choices to wait, adjust, or cancel.
- Server validates eligibility, filter allowlist, privacy, block lists, and rate limits. Client preview is informational and never authoritative.
- Next/Switch is disabled until 15 seconds from session start; End, Report, Block, Mute, and Camera Off remain immediate.
- Pairing is atomic, idempotent, one active session per user, with stale queue cleanup and cooldown.

## B. Real-time voice translation across calls
Applies consistently to stranger video, private video, private audio, profile-originated calls, chat-originated calls, accepted incoming calls, reconnects, Android, and Web/PWA:
- live speech/language detection, translated captions, original captions, selectable source/target languages, translation audio, original audio fallback, translation volume, caption size/position, feedback, and reconnect.
- Auto language detection and translation are enabled by default where supported and lawful; user can turn off translation/audio/captions independently.
- Translation is consent-aware, transparent, and never secretly records calls. Explain processing/provider/data retention before activation as required.
- Preserve original call audio when translation is unavailable, fails, or network degrades. Never make translation a prerequisite for call safety controls or call termination.
- Admin controls: service ON/OFF, UI hide, emergency stop, provider health, language allowlist, staged rollout, per-region/user rollout, restore, and rollback. Default service state ON, subject to availability, consent, policy, and user control.
- Admin switches cannot override user consent, encryption/security, or safety restrictions. Configuration changes are audited and versioned.

## C. Advanced messaging (WhatsApp-class capability, not a claim of parity)
- Canonical conversations reused after match/friendship; no duplicate thread.
- Text, voice notes, images, approved files/video, reply, reactions, controlled edit window, delete-for-me, policy-based delete-for-everyone, forwarding controls, typing, delivery/read receipts, mute/archive/pin, local search, disappearing-message settings, safe link previews, media preview, attachments scanning before delivery, and call shortcuts.
- Audio/video call buttons create request/accept flows; friendship does not imply consent. Recipient must accept.
- Message send uses server authorization, conversation membership, block checks, rate limits, idempotency, durable persistence, delivery events, and retry-safe client acknowledgement.
- Message status is server-authoritative; offline queue is encrypted locally and expires according to policy.
- Search is local/decrypted on participant devices by default; server cannot index plaintext E2EE messages.
- Block immediately disables messaging, calls, and matching between the parties, including pending requests and active sessions.

## D. E2EE and privacy-preserving safety
- E2EE remains genuine: only participant devices hold message-decryption keys; server/Admin has no universal plaintext key or hidden backdoor.
- No blanket admin-readable chat archive, silent monitoring, or automatic ZIP of all users' conversations.
- Safety analysis must be transparent and privacy-preserving (e.g. on-device signals, metadata abuse detection with minimization, or content the user explicitly reports). Clearly disclose any optional AI processing and obtain required consent.
- User report can submit selected messages/evidence; evidence export is scoped to a case, access-controlled, audited, encrypted at rest, retention-limited, and legally reviewed.
- ZIP export is only for authorized case evidence, never indiscriminate chat backup. Include case ID, timestamps, integrity manifest/hash, access log, and redaction controls where appropriate.
- Reported evidence is distinguishable from unverified AI signals; AI risk scores are not proof and cannot alone cause irreversible punishment.

## E. Safety, abuse prevention, and incident workflow
Retain/add:
- harassment, threats, blackmail/extortion, self-harm/suicide risk, credible violent/terrorist threat signals, scams/spam, malicious links, repeated unwanted contact, block evasion, and reported-content triage.
- Exclude grooming/sexual-exploitation indicators as a general monitoring category per owner direction.
- Keyword hits are context-sensitive signals, not automatic guilt. Educational/news/help-seeking context must not be treated as a violation solely by keyword.
- Severity levels: informational, low, medium, high, critical; configurable escalation, human review, appeals, and false-positive handling.
- Critical alerts use an incident queue and on-call notification policy; do not promise literally instantaneous delivery where providers/network can fail.
- Safety controls: report, block, mute, camera off, end call, leave session immediately. Minimum 15-second Next rule never delays these.
- No automatic call recording or covert camera/mic activation.

## F. Admin security and operations
Admin modules:
1. AI Safety/Moderation Queue
2. Incident Center (case, severity, evidence, owner, SLA, status, audit)
3. Chat Report Review (only user-submitted/scoped evidence)
4. E2EE Health (protocol/key/session health; no plaintext access)
5. Evidence Vault (case-scoped export, retention, access audit)
6. IP/Device/Login Security (risk signals and session revocation)
7. Stranger Safety (block/report patterns, match restrictions)
8. Translation Service Control and Health
9. Chat Service Health and abuse metrics
10. Call Diagnostics (connection/jitter/loss/ICE/TURN; no private media)
11. Feature Flags/Remote Config (validation, staged rollout, rollback)
12. Admin RBAC, approvals, immutable audit, incident response.

IP-derived location is approximate, not a precise address. Precise GPS is not exposed to strangers and is collected only with explicit permission and a justified feature. Restrict IP/device data to authorized security roles, purpose limitation, retention, and audited access.

Admin may stop/hide/restrict/restore an add-on service at any time. Emergency stop cannot disable core encryption, authentication, consent, report/block, or safety exits. No-code controls mitigate/rollback configuration; code defects still require code changes and verified release.

## G. Realtime contracts (illustrative; final schemas versioned)
- `match.queue.status`, `match.paired`, `match.cancelled`, `match.session.ended`
- `call.requested`, `call.ringing`, `call.accepted`, `call.rejected`, `call.expired`, `call.joining`, `call.connected`, `call.reconnecting`, `call.ended`, `call.failed`
- `chat.message.created`, `chat.message.delivered`, `chat.message.read`, `chat.typing`, `chat.reaction.updated`, `chat.message.edited`, `chat.message.deleted`
- `translation.status`, `translation.caption`, `translation.health` (captions routed only to authorized call participants)
- `safety.report.created`, `safety.case.updated`, `safety.alert.created`, `safety.block.applied`
- `admin.config.changed`, `admin.rollout.updated`, `admin.service.stopped`, `admin.service.restored`
All events require authorization, schema validation, versioning, correlation IDs, replay protection where relevant, and no sensitive plaintext in logs.

## H. Security baseline
- Server-side authorization on every endpoint and realtime channel; deny-by-default RLS.
- OAuth state/nonce/PKCE and server-verified Google identity; secrets server-side.
- Input validation, output encoding, rate limits, abuse quotas, idempotency keys, secure uploads, malware scanning, signed webhook verification.
- Encryption in transit and at rest; E2EE for message content; secure device key storage.
- Admin least privilege, MFA/step-up, separation of duties for evidence access, immutable audit, alerting, and break-glass review.
- Dependency/Supply-chain scanning, secret scanning, CI security gates, vulnerability disclosure and incident response.
- No system can promise zero hacking or zero bugs; use defense-in-depth, continuous testing, monitoring, response, and recovery.

## I. Screen integration checklist
- Match lobby: filters, preview, apply/reset, 15-second Next countdown, queue status.
- Stranger call: translation controls, captions/audio modes, health/reconnect, immediate safety actions.
- Private call: same translation controls after consent and acceptance; audio/video parity.
- Profile and chat: call request shortcuts, explicit acceptance, canonical chat.
- Chat: advanced message actions, E2EE indicator, report selected messages, block, translation, call shortcuts.
- Settings: language, translation, privacy, receipts, retention, AI consent, devices, data export/delete.
- Notifications: safety alerts and call/message deep links revalidate authorization and block state.
- Admin: service toggles, rollout, health, incidents, evidence, security, audit and restore.

## J. Acceptance gates (not yet verified)
- Every screen/button maps to handler → API/domain operation → persistence → realtime event → navigation/error recovery.
- No dead controls, orphan routes, duplicate chat/call/match engines, or silent filter changes.
- E2EE threat model and independent protocol review; prove Admin cannot decrypt ordinary private chats.
- Translation consent, fallback, latency, language and provider failure tests.
- 15-second Next test plus immediate End/Report/Block tests.
- Report/evidence ZIP access, encryption, integrity, retention, and audit tests.
- Abuse false-positive/appeal tests and Admin emergency stop/restore tests.
- Android + browser real-device call, network-switch, reconnect, permission-denial, and load tests.
- Red-team findings closed by severity; release and production launch require owner approval.

## Status
This is a product/technical scope specification only. It does not claim implementation, integration, deployment, or verification. The detailed screen-by-screen wiring, API schemas, database migrations, implementation, test evidence, and owner review remain tracked work.
