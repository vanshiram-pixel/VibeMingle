# Instant Stranger Video Matching — Product & Engineering Spec

Status: SPECIFIED (design only; not implemented or runtime-verified)
Scope: VibeMingle V1 basic stranger matching + video handoff. Advanced ranking remains V2.

## User journey (locked from product clarification)
1. Two authenticated, age-eligible strangers independently tap **Start Stranger Matching**.
2. The matchmaking service pairs two eligible users atomically. If a compatible waiting peer already exists, target match-to-call activation is under 1 second (best-effort target, dependent on network, signaling and media permissions—not a guarantee).
3. Both clients receive the same match/session ID and enter the video-call screen automatically; neither user should have to accept a second confusing prompt after opting into matching. Camera/mic permissions and a clear stop/cancel control are required.
4. A newly matched pair has a **mandatory 15-second minimum interaction window**. Next/Skip is disabled for both during this window. This is a product floor, not a forced speaking/consent requirement: users can mute, turn camera off, or end/report/block immediately for safety. Safety exit always overrides the timer.
5. At/after 15 seconds, either participant may tap **Next Stranger**. The current pair is closed for that user; the other participant is safely returned to matching/available state only if they opted to continue. No ghost call or double assignment.
6. Next starts a fresh matchmaking attempt. Target: find the next distinct stranger promptly; the system may search/queue for up to **60–70 seconds** before showing a clear no-match/retry state. Do not promise two successful stranger connections in every 60–70-second interval; pool size, eligibility, network and consent determine availability. Avoid immediate rematching with the same person.
7. End/Stop Matching exits the queue and call cleanly.

## Matching rules
- Eligible: authenticated, age-gate passed, consented to stranger matching, online heartbeat fresh, not already in a call/match, not blocked in either direction, not banned/suspended, permissions/device readiness handled.
- One active match per user; enforce with database constraints/atomic transaction or server-side lock, not client-only checks.
- Pairing must be atomic and idempotent; retries cannot create duplicate sessions.
- Exclude recently seen/skipped pairs for a configurable cooldown; fairness should avoid repeatedly selecting the same available users.
- Respect user-set hard filters only where supported and consented; V1 should use safe basic eligibility, advanced ranking/preferences are V2.
- Queue state transitions: idle → searching → reserved → connecting → active (15-second floor) → next/end → idle/searching. Include expired, canceled, failed and safety-terminated outcomes.
- Match events are server-authoritative; clients cannot nominate arbitrary user IDs or forge a match.
- Presence heartbeat + TTL and server events/WebSocket/Realtime drive availability. One-second client polling is fallback/visual refresh only; do not run heavyweight SQL matchmaking every second.
- Keep camera/mic media peer-to-peer via WebRTC where possible; signaling and TURN credentials are authenticated and short-lived.

## UX & safety
- Visible Searching timer/status; target next-stranger rematch ≤1–2 sec when a compatible peer is waiting; if the pool is empty, continue searching and let the user cancel (no fixed 60–70 sec timeout).
- 15-second countdown indicator and disabled Next button; explain why.
- Safety controls always active: end call, report, block, camera off, mic mute. These override the minimum window instantly.
- After Next, show a brief connecting state; do not expose personal phone/email/location.
- Rate-limit matching/Next, detect automated abuse, and provide moderation/audit events without storing call content by default.
- Never match users who have blocked/reported each other or whose safety restrictions conflict.

## Performance targets (acceptance, not claims)
- When a compatible peer is already queued: server pairing event p95 target ≤1 sec; measure separately from media connection time.
- Next/rematch latency target: ≤1–2 sec with an eligible waiting peer. Empty-pool wait is open-ended with visible searching status and user cancel.
- Test concurrency/races, stale presence, simultaneous Next, network loss, permission denial, TURN fallback, and safety exits.
- Validate with at least two real accounts/devices and load tests before claiming production behavior.

## Open implementation dependencies
Auth/age/consent, presence lifecycle, block/report enforcement, call signaling/WebRTC/TURN, notification/deep-link behavior, staging environment and automated tests.
