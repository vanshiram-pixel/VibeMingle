# Matching engine foundation
- `types.ts`: queue/match domain contracts.
- `policy.ts`: deterministic preference compatibility and sanitization.
- `queue.ts`: in-memory reference adapter for unit/local exploration only; not distributed or production-safe.
- API POST queue intentionally returns 501 until trusted eligibility checks (adult/age assurance, consent, blocks, sanctions, region restrictions), atomic distributed queue, match-session persistence, LiveKit token minting, and abuse controls are implemented.
- Never expose raw queue membership or other users' private preference data.
