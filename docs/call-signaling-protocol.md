# VibeMingle WebRTC Signaling Protocol

This protocol is a contract; server implementation and security tests are required before use.

## Envelope
Every signal is sent over an authenticated private transport and bound to an existing call:
- `call_id` (UUID)
- `sender_id` (derived server-side from JWT; clients must not choose it)
- `kind`: offer | answer | ice | renegotiate | hangup
- `payload`: SDP or ICE fields, transient only
- `sequence` / server timestamp for ordering and diagnostics

## Server checks (every event)
1. Auth JWT is valid and user is one of exactly two call participants.
2. Session exists and is not terminal; sender is allowed for current phase.
3. Recipient is the other participant; no arbitrary channel/user targeting.
4. Block/privacy policy and rate limits are checked again.
5. Payload size/type is bounded; SDP/ICE never written to permanent analytics/logs.
6. Server relays only to the other participant and strips spoofable sender fields.

## Expected order
- Caller: server start -> callee accepts -> media permission -> create/set local offer -> relay offer.
- Callee: accepted -> media permission -> set remote offer -> create/set local answer -> relay answer.
- Both: set remote answer (caller), relay/add ICE candidates as they arrive; queue candidates until remote description is set.
- Peer connection state connected -> server transition connected; disconnected -> bounded reconnect; failed/closed -> terminate.
- Hangup requests server terminal transition and closes media on both clients.

## Reliability
- ICE candidate buffering until remote description ready.
- Deduplicate by candidate + mid + m-line index.
- Exponential reconnect with capped retries; revalidate call state before renegotiation.
- Signaling timeout and call-ring timeout handled by server, not client clocks.

## Deployment security
- Production TURN with short-lived credentials minted server-side; never embed static TURN secret in app.
- Realtime private channel authorization or Edge Function relay must be tested for participant isolation.
- Do not enable public broadcast channels for SDP/ICE.
- Audit event payloads and crash reporting to avoid leaking signaling/media data.
