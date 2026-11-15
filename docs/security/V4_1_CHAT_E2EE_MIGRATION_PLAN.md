# V4.1 — Chat E2EE Migration Plan (Non-destructive)

Status: SPECIFIED — implementation and security review pending
Branch: feat/typing-presence
Scope: Existing V4.1 chat only. No feature expansion.

## Finding
The current mobile repositories `chat_repository.dart` and `chat_repository_v2.dart` pass a plaintext `p_body` to `chat_send` and read `chat_messages` rows. This is incompatible with the V4.1 requirement that server storage and realtime payloads contain ciphertext only. Do not label current chat E2EE.

## Non-negotiable invariants
1. No server/admin universal decryption key or backdoor.
2. Client encrypts before upload; client decrypts after authorized retrieval.
3. Server accepts opaque ciphertext plus protocol metadata; never accepts a plaintext body field on the E2EE write path.
4. E2EE keys live in platform secure storage; never in logs, analytics, database rows or push payloads.
5. Attachments are encrypted on-device before object upload.
6. Realtime only transports ciphertext/opaque IDs and receipts; membership is server-authorized.
7. User-selected report evidence is an explicit separate flow, encrypted, scoped and audited.
8. Existing historical plaintext messages are not silently deleted or falsely represented as encrypted.

## Migration sequence (release-gated)
### E0 — Inventory and containment
- Enumerate all message reads/writes, RPCs, realtime subscriptions, notification previews, backups and analytics.
- Restrict database/RPC access to conversation participants; validate recipient and canonical conversation on server.
- Remove plaintext from diagnostic logs and telemetry.
- Preserve existing data pending an explicit historical-message policy.

### E1 — Protocol decision
- Evaluate maintained audited libraries/protocols for Flutter/mobile, web/PWA and multi-device.
- Document threat model, device identity, signed prekeys, session establishment, forward secrecy, key rotation/revocation, device loss/recovery, verification UX and group/fan-out strategy.
- Obtain cryptographic/security review before selecting or shipping a protocol. Do not implement custom cryptography.

### E2 — Additive storage
- Add ciphertext envelope columns/table and protocol/key epoch metadata in an additive migration.
- Include client message UUID/idempotency, sender/recipient, server timestamp, receipt/tombstone metadata.
- Enforce ciphertext-only new writes with a dedicated RPC and database constraints/privileges.
- Keep legacy plaintext read path isolated and access-controlled only for migration/retention; never write new plaintext.
- Define retention/expiry and deletion behavior before backfill. No blind migration that destroys old content.

### E3 — Client integration
- Implement key lifecycle and secure storage; encrypt/decrypt through vetted library.
- Replace both duplicate repository implementations with one canonical abstraction; prevent plaintext body from reaching Supabase.
- Add encrypted attachment pipeline and safe push previews.
- Add client-side search only over locally decrypted content.
- Add explicit device/key-change handling and recovery UX.

### E4 — Authorization and realtime
- Derive actor from JWT; reject client-supplied sender identity.
- Check conversation participant membership, block state, account state and message size at server.
- Private realtime channel authorization must prove membership; typing/presence is ephemeral and rate-limited.
- On reconnect, re-fetch authoritative encrypted messages and deduplicate by client message ID.

### E5 — Historical data and rollout
- Decide whether legacy messages remain visibly marked “legacy (not E2EE)”, are user-exported, or are deleted after notice/retention; never silently relabel.
- Roll out behind server feature flag to internal test accounts, then two-device closed beta.
- Roll back by disabling new send path, not by exposing/decrypting ciphertext.
- Gate release on independent security review and tests below.

## Required acceptance tests
- Database/API rejects plaintext `body` on E2EE send endpoint.
- Cross-user and blocked-user read/write attempts fail.
- Ciphertext is unreadable in DB, logs, push, admin and realtime inspection.
- Correct recipient decrypts; wrong user/device cannot.
- Replay/idempotency prevents duplicate messages.
- Key rotation/revocation and device loss scenarios pass.
- Attachments remain encrypted at rest and access is signed/short-lived.
- Report evidence only appears after explicit selection/consent and has audit/retention.
- Android + web interoperability and reconnect/offline queue tests pass.
- Security review findings closed; build and integration evidence recorded.

## Current status
- Contract baseline: SPECIFIED.
- Existing plaintext path: identified.
- E2EE protocol/library: NOT SELECTED.
- Additive migration: NOT APPLIED.
- Client crypto integration: NOT IMPLEMENTED.
- Security/device tests: NOT RUN.
- Production data: untouched by this plan.
