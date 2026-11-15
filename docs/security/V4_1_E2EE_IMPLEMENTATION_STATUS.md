# V4.1 Chat E2EE — honest status & implementation checklist

| Component | Status |
|---|---|
| Additive ciphertext DB lane | COMMITTED (migration 0007; not applied) |
| E2EE key architecture | SPECIFIED |
| Device bootstrap scaffold | COMMITTED (not a cryptographic identity) |
| Audited E2EE protocol dependency | NOT SELECTED / NOT INSTALLED |
| Android secure private-key storage | NOT IMPLEMENTED |
| Public device bundle registry | NOT IMPLEMENTED |
| Encrypt/decrypt + ratchet | NOT IMPLEMENTED |
| Client message repository migration | NOT IMPLEMENTED |
| Legacy plaintext send shutdown | NOT IMPLEMENTED |
| Two-device security verification | NOT RUN |

## Immediate implementation order
1. Select a maintained E2EE protocol library only after platform/API/license/security review; do not implement primitives ourselves.
2. Implement secure storage adapter for private identity/session state and lifecycle tests.
3. Add device bundle schema and authenticated register/revoke/pre-key RPCs.
4. Implement session bootstrap, ciphertext envelope serialization, encrypt/decrypt and replay/idempotency behavior.
5. Replace chat send/read path with envelope RPC and locally decrypted view model; keep legacy history read-only and clearly labeled.
6. Add attachment encryption and encrypted key payload.
7. Run two-device staging tests and independent security review.
8. Disable plaintext writes only after migration readiness and rollback strategy approved.

## Release rule
Until all gates pass, UI must not claim messages are E2EE. Never put plaintext into the new ciphertext table or use the install reference as a key.
