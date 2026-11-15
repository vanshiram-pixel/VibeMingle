# V4.1 P02 — Domain, API & Security Contracts (Baseline)
Status: SPECIFIED baseline; implementation pending
Version: 1.0

## Contract rules
- All authenticated endpoints derive actor identity from verified session/JWT; never trust client-supplied actor IDs.
- Validate UUIDs, enums, bounded strings, payload sizes and pagination on server.
- Use standard response envelope: `{data, error, request_id}`; errors are stable machine codes, not raw SQL/provider errors.
- Mutations accept an idempotency key when retries could duplicate state (requests, match join, calls, payments, rewards).
- Enforce rate limits server-side; audit privileged/admin actions.
- Realtime is notification/transport only. Database/server state is authoritative; clients re-fetch or reconcile after reconnect.
- Every operation checks block, privacy, consent, account status and relationship authorization as applicable.
- Do not log message plaintext, E2EE keys, access tokens, TURN secrets, payment credentials or report evidence contents.

## API namespaces (logical contract; concrete transport may be RPC/REST)
### Identity / account
- `POST /v1/auth/google/callback` — OAuth exchange/verification is provider SDK callback + server session validation; not a client-supplied identity assertion.
- `GET /v1/me` — profile, account status, consent version/status, age eligibility flags (minimal).
- `PATCH /v1/me/profile` — validated profile changes.
- `POST /v1/me/consents` — record named consent/version/choice/time; never bundle optional AI consent into mandatory terms.
- `POST /v1/me/sessions/revoke`, `POST /v1/me/delete`, `GET /v1/me/export` — lifecycle operations with re-auth/confirmation and audit as appropriate.

### Social / connections
- `GET /v1/discovery/people?cursor=&filters=`
- `POST /v1/friend-requests` `GET /v1/friend-requests?direction=incoming|outgoing`
- `POST /v1/friend-requests/{id}/accept|decline|cancel`
- `DELETE /v1/friends/{userId}`
- `POST /v1/follows/{userId}`, `DELETE /v1/follows/{userId}`
- `GET /v1/connections?kind=friends|requests|followers|following`
- `POST /v1/blocks/{userId}`, `DELETE /v1/blocks/{userId}`
- All discovery/list endpoints apply visibility and block filters before returning data; cursor pagination only.

### Chat (E2EE)
- `POST /v1/conversations` — server canonicalizes participant pair/relationship and returns stable thread ID.
- `GET /v1/conversations`, `GET /v1/conversations/{id}/messages?cursor=`
- `POST /v1/conversations/{id}/messages` — encrypted envelope only; idempotency key.
- `POST /v1/messages/{id}/delivered`, `POST /v1/messages/{id}/read`
- `PATCH /v1/messages/{id}`, `DELETE /v1/messages/{id}` — sender/time/recipient policy; edit is a new authenticated ciphertext revision or protocol-defined tombstone.
- `POST /v1/messages/{id}/reactions`, `POST /v1/messages/{id}/reports`
- `POST /v1/conversations/{id}/attachments` — upload intent; signed upload; scan; attach encrypted metadata.
- `POST /v1/conversations/{id}/typing` — short-lived private signal; never persisted as message history.
- `POST /v1/conversations/{id}/call-requests` — private call request only; receiver acceptance required.
- Server cannot decrypt content. Search is client-side for decrypted content; server indexes only minimal non-sensitive metadata.

### Match / stranger video
- `POST /v1/matches/queue` — filters + consent + eligibility + client request id.
- `GET /v1/matches/{queueId}` — status; realtime event is advisory.
- `POST /v1/matches/{queueId}/cancel`
- `POST /v1/matches/{sessionId}/next` — enforce 15-sec server cooldown.
- `POST /v1/matches/{sessionId}/end`, `POST /v1/matches/{sessionId}/report`, `POST /v1/matches/{sessionId}/block`
- `POST /v1/matches/{sessionId}/friend-request`, `POST /v1/matches/{sessionId}/follow`
- Server performs atomic pairing, compatible filter intersection, one-active-session enforcement, TTL cleanup and session authorization. Empty compatible pool remains searching/cancellable; never silently broaden filters.

### Private calls
- `POST /v1/calls` (request recipient, media type, idempotency key)
- `POST /v1/calls/{id}/accept|reject|cancel`
- `POST /v1/calls/{id}/end`
- `POST /v1/calls/{id}/join-token` — only accepted participants; short-lived, audience/room-bound token.
- `POST /v1/calls/{id}/ice` or authorized realtime signaling channel.
- Call request != accepted call. Friendship alone never authorizes joining.

### Translation
- `POST /v1/translation/sessions`, `PATCH /v1/translation/sessions/{id}/preferences`, `POST /v1/translation/sessions/{id}/stop`
- Consent and service availability checked; original audio/text path remains available.
- Provider credentials server-side; no persistent recording by default; redact provider logs.

### Safety / support
- `POST /v1/reports` (target type/id, reason, optional selected evidence, context consent)
- `GET /v1/reports/{caseId}`, `POST /v1/reports/{caseId}/appeal`
- `POST /v1/blocks/{userId}` and immediate local safety exit; server block must be committed and enforced across all domains.
- Evidence is minimal, selected, encrypted, access-controlled, audited and retention-limited.

### Notifications
- `GET /v1/notifications?cursor=`, `POST /v1/notifications/{id}/read`, `PATCH /v1/notification-preferences`
- Push payloads contain opaque IDs and generic text; re-authorize on deep-link opening.

### Wallet / payments / rewards
- `GET /v1/wallet`, `GET /v1/ledger?cursor=`, `POST /v1/purchases`, `POST /v1/gifts`
- Provider webhooks verify signature, idempotency and transaction; clients never write balances.
- `GET /v1/rewards`, `POST /v1/rewards/{id}/claim`, `POST /v1/referrals`; eligibility and ledger writes server-only.

### Admin/Ops (separate protected namespace)
- `GET /ops/health`, `GET /ops/incidents`, `GET /ops/matches`, `GET /ops/calls`, `GET /ops/translation`, `GET /ops/moderation/cases`
- `POST /ops/flags`, `POST /ops/rollout`, `POST /ops/emergency-stop`, `POST /ops/rollback`
- `POST /ops/cases/{id}/actions`, `POST /ops/evidence/{id}/export`
- Every action requires role, scope, reason, MFA/step-up where sensitive, and immutable audit entry. Admin has no general chat decryption capability.

## Canonical domain entities (logical; final migrations must reconcile current SQL)
- `profiles`: user_id, username, display_name, bio, avatar/media refs, visibility, locale, updated_at.
- `consents`: user_id, consent_type, policy_version, decision, timestamp, source.
- `friend_requests`: id, sender_id, recipient_id, status, created/updated; unique pending pair.
- `friendships`: canonical low/high user IDs, created_at; unique pair.
- `follows`: follower_id, followed_id, created_at; unique pair; no self-follow.
- `blocks`: blocker_id, blocked_id, created_at; unique pair; no self-block.
- `conversations`: stable ID, participant pair/relationship, created_at, state; server canonicalization.
- `messages`: id, conversation_id, sender/recipient, ciphertext envelope, protocol/key version, client nonce, server timestamp, delivery/read/tombstone metadata. No plaintext body.
- `message_revisions/reactions`: authenticated ciphertext or protocol-safe metadata; no plaintext search index.
- `attachments`: opaque object key, encrypted metadata, scan state, size/type, retention.
- `match_queue/match_sessions`: user, server filters, status, queue TTL, pair/session IDs, state/version, timestamps; constraints enforce one active session/user.
- `calls`: requester/recipient, state, media, expiry, accepted_at/ended_at, room ref; one-time join token metadata.
- `signaling`: ephemeral authorized room events, TTL; no client-selected arbitrary room access.
- `translation_sessions`: participants, consent, languages, state, provider health/latency metadata (no raw audio retention).
- `reports/case_evidence/audit_events`: case scope, actor, reason, encrypted evidence refs, access/retention logs.
- `notifications/device_tokens/preferences`: private per-user delivery settings.
- `wallet_ledger/purchases/webhook_events/rewards`: append-only/idempotent financial events; balances derived or reconciled.
- `admin_roles/admin_audit/feature_flags/incidents`: least privilege, versioned configuration and traceability.

## E2EE decision baseline (must be implementation-reviewed)
- Use a vetted, maintained cryptographic protocol/library; do not invent crypto.
- Establish per-device identity keys, signed prekeys and session key agreement; define multi-device fan-out, rotation, revocation, recovery and verification UX.
- Message encryption/decryption only on clients; server persists opaque ciphertext and protocol metadata.
- Key material stays in platform secure storage; never logs/backups plaintext keys.
- Attachments encrypted client-side before upload; short-lived signed object access.
- Push, search, analytics and admin contain no plaintext.
- Report evidence is an explicit user action selecting content and consent; evidence is encrypted and separated from normal message storage.
- Threat model, protocol choice and implementation must be reviewed before claiming E2EE.

## Event naming baseline (private, authenticated, versioned)
- `social.friend_request.created|updated`, `social.friendship.created|removed`, `social.follow.changed`, `safety.block.changed`
- `presence.changed` (privacy-filtered), `match.queue.status`, `match.session.created|ended`
- `chat.message.new` (ciphertext only), `chat.message.receipt`, `chat.typing` (ephemeral)
- `call.requested|accepted|rejected|ended`, `call.signal` (authorized participants only)
- `translation.status|caption` (consented recipients only)
- `notification.created`, `wallet.ledger.updated`, `reward.claimed`
Events include schema version, entity ID, actor/recipient scope and timestamp; clients must deduplicate and re-fetch authoritative state.

## P02 acceptance
- [ ] API contracts converted to OpenAPI/typed schemas.
- [ ] DB ERD and migration plan reconciled with existing 0001–0006.
- [ ] RLS/privilege matrix written for every table/RPC.
- [ ] E2EE protocol/library decision and threat model reviewed.
- [ ] Realtime channel membership/authorization contracts specified.
- [ ] Error taxonomy, idempotency, rate-limit and observability contracts approved.
- [ ] Contract tests drafted/executable.
Status: IN_PROGRESS — contract baseline documented; schema/code implementation and test evidence pending.
