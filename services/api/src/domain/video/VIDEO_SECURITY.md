# LiveKit token and room security
- Never accept room name, LiveKit identity, grants or participant IDs from client payload.
- Derive room name from an active server-side match/call session; identity is the authenticated Supabase user UUID.
- Validate session membership, age assurance, sanctions, bilateral blocks and session state before issuing any token.
- Issue short-lived grants (default 120s, hard cap 300s); grant publish/subscribe only as needed.
- Never expose API secret in Flutter/web; only API service may sign tokens.
- Room creation and session state are server-authoritative; webhook events must be signature-verified and idempotent.
- No recording by default; disclose and separately consent before any future recording.
- Do not log tokens, room credentials, raw audio/video or sensitive metadata.
- Current implementation is policy/types only; LiveKit SDK, DB lifecycle, credentials and integration tests are pending.
