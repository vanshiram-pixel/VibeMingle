# V4.1 Advanced E2EE Delivery Gate (No MVP)

**Status: NOT production-ready; encryption protocol and client wiring are incomplete.**

## Implemented foundations
- Additive `chat_envelopes` transport schema and participant-only row visibility.
- Server-derived canonical conversation IDs (UUID ordering).
- Guarded send RPC with mutual-friend requirement, bilateral block checks, idempotency key, ciphertext size/version/epoch validation.
- Delivery/read receipts are recipient-only RPCs.
- Device registry, revocation, signed-prekey metadata, one-time-prekey publication and atomic claim RPCs.
- Mobile envelope transport wrapper does not accept a plaintext body.
- Non-secret install reference is explicitly documented as diagnostic-only.

## Explicitly not implemented (must not be advertised as complete)
- A reviewed Signal Protocol implementation (X3DH/PQXDH + Double Ratchet or equivalent audited protocol).
- Secure private-key generation, Android Keystore-backed persistence, backup/recovery and device migration.
- Cryptographic verification of identity/signed-prekey signatures and trust-change UX.
- Multi-device session establishment, ratchet state persistence, replay/duplicate protection at protocol layer, attachment encryption, key rotation and forward secrecy tests.
- Chat screen migration from legacy `chat_send(p_body)` to encrypted envelopes; existing plaintext repository remains legacy.
- Integration tests proving sender/recipient decrypt successfully on two real devices and server/operator cannot decrypt.
- Coordinated disablement/migration of plaintext writes without breaking existing chat/history.

## Release-blocking actions
1. Select and pin a maintained audited protocol implementation; threat-model review before custom cryptography.
2. Implement platform secure storage and key lifecycle; never store private keys in Supabase or logs.
3. Add encrypted attachment pipeline and protocol metadata/version negotiation.
4. Wire message composer, inbox, realtime stream, offline queue, retry/idempotency, receipts and UI to envelope transport.
5. Add migration strategy for legacy history and enforce a clearly labeled legacy-history boundary.
6. Add automated protocol vectors, tamper/replay tests, device revocation tests, two-device integration and security review.
7. Only after tests pass, revoke legacy plaintext send permissions in a coordinated migration and enable E2EE UI.
8. Do not deploy this migration to any Supabase project until VibeMingle's dedicated staging project is confirmed.

## Acceptance criteria
- No plaintext body reaches database/network from new-message composer.
- Encryption/decryption happens only on endpoints; metadata does not expose message content.
- Sender/recipient identity and signatures verified; malicious/invalid envelope rejected.
- Message retries are idempotent; duplicate/replay cannot mutate payload or ratchet state.
- Block/revoke immediately prevents new sends and invalidates active sessions as specified.
- Two independent Android devices pass send/receive, restart, offline retry, key-change and revoke scenarios.
- CI, staging migration tests, RLS tests and security review are green.
