# LiveKit call flow (implementation baseline)
1. Authenticated user asks API to join a session using its UUID.
2. API loads session from trusted database and confirms actor is one of its two participants.
3. API checks session is joinable, account age assurance and consent are current, no sanctions, and no bilateral block.
4. API derives room name and identity itself; client never supplies grants/identity/room.
5. Server signs a short-lived token (120 seconds default; max 300 seconds); Flutter connects to LiveKit.
6. LiveKit webhooks are signature-validated and idempotently transition session state; API handles leave/end and reconnect grace.
7. Session ends on explicit exit, participant disconnect timeout, safety action, or moderation action.
## Current status
Server SDK wrapper and secret config are committed. Token endpoint intentionally returns 503 until trusted DB membership/safety checks exist. No token is currently minted from API routes. No provider credentials or room/webhook setup is configured.
