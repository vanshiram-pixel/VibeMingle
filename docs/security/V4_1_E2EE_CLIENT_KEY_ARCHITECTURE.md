# V4.1 E2EE Client Key Architecture (Implementation Contract)

Status: SPECIFIED / CLIENT IMPLEMENTATION PENDING.
This contract is a design gate, not a claim that the app currently encrypts messages.

## Threat model and non-negotiables
- Message plaintext is created/read only on participant devices.
- Supabase stores ciphertext, protocol metadata, delivery/read timestamps and routing identifiers only.
- No service-role/admin key in mobile/web clients.
- Admin/moderation cannot decrypt ordinary private conversations. User-submitted evidence is a separate explicit, scoped flow.
- Do not invent cryptography. Use a maintained, audited protocol/library and its supported primitives; do not roll custom crypto.
- TLS remains mandatory. E2EE does not replace transport security.

## Key lifecycle
1. On first authenticated device, generate a device identity key pair using an audited library and secure random source.
2. Persist private key material only in platform secure storage (Android Keystore-backed storage; browser secure storage strategy documented separately). Never put private keys in Supabase, logs, backups, analytics or ordinary preferences.
3. Publish a signed public device bundle: identity public key, signed pre-key, bounded one-time pre-key inventory, device ID, protocol/version. Server validates authenticated ownership and immutable device IDs; public keys are not secrets.
4. Initiate session with recipient's active device bundle using a reviewed asynchronous ratcheting protocol (e.g. Signal-style X3DH/PQXDH + Double Ratchet only if a supported, audited implementation is available). Pin protocol/library version and security review.
5. Encrypt each message client-side; create unique client_message_id; submit ciphertext + protocol_version + key_epoch to `chat_send_e2ee`. Never send plaintext in RPC or telemetry.
6. Recipient verifies envelope metadata, decrypts locally, and updates read/delivery receipt without plaintext.
7. Multi-device: each device has its own identity/session. Sender encrypts one envelope per recipient device (and sender's linked devices if history sync is explicitly supported); never assume one account key unlocks all devices.
8. Rotation/revocation: signed device-list updates; revoke compromised device, invalidate sessions, notify peers, and require fresh session establishment. Key changes show a safety warning/verification affordance.
9. Lost device: server cannot recover private keys. Recovery must be explicit user-controlled encrypted backup/recovery-key flow; no silent server escrow.
10. Logout: lock/clear in-memory keys and session material; preserve or wipe local encrypted data according to user choice and shared-device safety.

## Device registry contract
A future migration/API must support:
- `user_devices`: device_id, user_id, public bundle, protocol version, created/last_seen, revoked_at.
- authenticated register/update/revoke RPCs; public read only of non-revoked recipient bundles.
- immutable device ownership; no client-supplied user_id trust.
- rate limits and abuse controls on pre-key replenishment.
- key transparency/audit strategy and user-visible safety-number verification.

## Client storage and UI
- Android: private key through Keystore-backed secure storage; encrypted local DB for cached ciphertext.
- Web/PWA: browser threat model documented; XSS can access unlocked app memory, so CSP, dependency hygiene and strict sanitization are required. Do not promise protection against compromised browser/device.
- Lock screen notifications default to generic sender/message alert; no plaintext preview unless user explicitly opts in.
- Search/indexing occurs locally on decrypted content; server search cannot index plaintext.
- Attachments: encrypt file with random content key; upload ciphertext only; send file key inside E2EE message; authenticated encrypted metadata and bounded download.
- Edit/delete/reaction/forward/quote operations are authenticated protocol events or encrypted payloads; server stores only minimal routing/receipt metadata.

## Rollout gates (must all pass)
- Two independent devices/accounts can establish session and exchange encrypted messages.
- DB/network inspection confirms no plaintext in message body, RPC args, logs or realtime payload.
- Tampered ciphertext, replay, duplicate client IDs, wrong recipient, revoked device and block cases fail safely.
- Key rotation/device loss/reinstall behavior documented and tested.
- Dependency license, maintenance, cryptographic audit and mobile/web compatibility reviewed.
- Legacy plaintext send is disabled for new messages only after client rollout and migration acceptance; legacy history remains explicitly labeled legacy and is not falsely represented as E2EE.
- Independent security review and staging acceptance before any production migration.

## Current implementation status
- Additive ciphertext table/RPC: committed in migration 0007, not applied.
- Device registry, protocol library, secure key storage, encrypt/decrypt, encrypted attachment flow: NOT IMPLEMENTED.
- E2EE: NOT VERIFIED; do not display an “End-to-end encrypted” guarantee in UI yet.
