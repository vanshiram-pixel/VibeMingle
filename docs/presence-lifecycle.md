# Presence lifecycle and privacy

- On authenticated app foreground: set presence online and begin a bounded heartbeat (e.g. every 60–90 seconds).
- On background/inactive: set away; on explicit sign-out: set offline.
- A stale online record is not proof of active use. UI should show “last seen”/unknown after a configurable freshness window.
- Presence visibility is restricted to self and accepted friends by RLS. Blocked users must not be visible; add block filtering to the policy before production.
- Do not expose GPS, IP, device identifiers, or exact activity details through presence.
- Keep a single heartbeat per session; cancel timers/subscriptions on logout and dispose.
- Multi-device sessions need an aggregate model (online if any active session; offline only when all sessions expire). Current user_presence row is a simple MVP representation.
- Verify RLS with unrelated, blocked, and friend accounts before release.
