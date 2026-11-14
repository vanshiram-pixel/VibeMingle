# LiveKit Call Authorization — V3

## Server flow
1. Client obtains a Supabase access token and sends it as Bearer auth to `POST /v1/calls/token` with a UUID `sessionId`.
2. API validates the Supabase token using Auth `getUser`; it never trusts a client-supplied identity.
3. API uses the server-only Supabase service-role client to call `call_session_authorize`. The RPC verifies session existence, participant membership, joinable state, both directions of pair blocking, and current terms/privacy/age-assurance consent for the caller.
4. API atomically marks the session active for a participant and mints a short-lived (120-second) LiveKit JWT scoped to the deterministic session room and authenticated UUID identity.
5. Client connects to LiveKit using the returned URL/token. It must not expose API secret or service-role key.
6. Client sends `POST /v1/calls/:sessionId/leave`; server verifies membership and ends the session through a service-only RPC.

## Required deployment
- Apply Supabase migrations in order through `0012_call_session_authorization_rpc.sql`.
- Set API-only `SUPABASE_SERVICE_ROLE_KEY`, `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`; never put these in Flutter/web builds.
- Configure LiveKit project/network permissions and app privacy notices.
- Add integration tests for participant/nonparticipant, ended sessions, revoked consent, block edges, expired tokens, and leave authorization.
- A successful CI build is not evidence of a deployed database migration or a working LiveKit project.

## Current limitations
- This API layer issues a token after session authorization, but does not yet implement a production matchmaking queue/session creation flow.
- No mobile LiveKit connection or call UI lifecycle is wired yet.
- Session status currently becomes active when the first participant obtains a token; a two-participant join handshake and timeout cleanup remain future hardening.
- Re-check consent/blocks immediately before each participant token (done by authorization RPC); production moderation/sanction and jurisdiction/age-assurance provider integration remains required.
