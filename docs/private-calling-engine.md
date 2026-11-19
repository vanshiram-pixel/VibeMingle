# VibeMingle — Private Calling Engine (Architecture & Implementation Contract)

Status: next development milestone; architecture specification.

## User flow
1. Caller taps Audio Call or Video Call from an accepted friend's profile/chat.
2. Server validates auth, friendship/relationship policy, block state, and call limits.
3. Server creates a call session in `ringing` state and emits a targeted incoming-call notification to callee.
4. Callee sees full-screen incoming call UI with caller identity, call type, Accept and Decline.
5. Accept transitions session to `connecting`; both clients exchange WebRTC signaling through authenticated server events.
6. ICE connectivity succeeds -> `connected`; show duration and controls.
7. Either party hangs up -> `ended`; persist call log and notify peer.
8. Timeout, decline, busy, offline, permission denial and network failure have explicit terminal states.

## State machine
`created -> ringing -> accepted -> connecting -> connected -> ended`
Terminal alternatives: `declined | missed | cancelled | busy | failed`.
Only the server may authoritatively transition call status; clients request transitions.

## Signaling and media
- WebRTC for audio/video media; signaling transports offer/answer and ICE candidates only.
- Use authenticated Supabase Realtime/private channels or Edge Functions for signaling; authorize each event against call participants.
- TURN relay is required for reliable NAT/firewall traversal; STUN alone is insufficient.
- Never store raw audio/video in database. Do not record calls by default.
- Video starts only after explicit acceptance and camera permission.
- Audio/video mute, camera toggle, speaker route, front/back camera, and hang-up controls.
- Reconnect strategy and network-quality indicators; graceful fallback to audio if user chooses.

## Database outline (migration required)
- `call_sessions`: id UUID, caller_id, callee_id, call_type(audio/video), status, created_at, ringing_at, accepted_at, connected_at, ended_at, end_reason, duration_seconds.
- `call_events`: session_id, actor_id, event_type, created_at, minimal metadata; no SDP/ICE long-term persistence.
- RLS: participants only read their sessions/events; clients cannot directly set privileged status/timestamps.
- Server RPC/Edge Function validates participant, friend/block policy and allowed state transitions.
- Add indexes for caller/callee + created_at and status + ringing_at for expiry jobs.

## Notifications
- Incoming call push includes opaque call_id and caller display-safe identity only.
- Never include SDP, ICE candidate, private tokens, or sensitive profile data in push.
- Handle foreground, background and terminated app separately; platform call UI integration is a later native task.
- Missed-call notification and call history must deduplicate by call_id.

## Safety/privacy
- Blocked users cannot initiate calls; block takes effect immediately.
- Rate limit call attempts and ring duration; prevent call-spam.
- Require explicit microphone/camera permission; explain purpose and handle denial.
- Provide report/block controls from call screen and history.
- Respect account privacy settings and age/safety policies.
- No location collection or call recording.

## Acceptance tests
- Caller/callee state machine and invalid transition tests.
- Friend-only authorization; blocked/non-member cannot signal.
- Accept/decline/timeout/busy/offline/missed flows.
- WebRTC two-device audio/video, TURN relay, network switch/reconnect.
- Permission denied, app background/foreground, notification tap routing.
- Call log accuracy, duration, deduplication and privacy checks.
- Build/test CI and secrets/config audit before release.

## Implementation sequence
A. SQL schema + RLS + RPC/Edge Functions.
B. Flutter call repository and typed call-state model.
C. Incoming call UI + notification routing.
D. WebRTC audio call MVP + TURN.
E. Video controls + camera permissions.
F. Call history, missed calls, block/report.
G. Integration tests on two physical devices; CI; release checklist.

Current repository scaffold limitation: this spec is committed before executable integration; do not represent calling as production-ready until A–G and security testing pass.
