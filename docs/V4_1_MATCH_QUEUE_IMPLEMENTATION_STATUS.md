# V4.1 Match Queue Implementation Status

- Added migration `0011_match_queue_foundation.sql`: queue intent table, private RLS, enter/heartbeat/leave RPCs, presence freshness and busy-session guards.
- Added mobile `MatchQueueRepository`: enter/heartbeat/leave client methods.
- Queue intent does **not** produce a match. Pairing requires a dedicated transactional worker/service that locks both users and validates consent, age eligibility, bilateral filters, blocks, cooldowns, stale queue, busy sessions and fairness. No peer IDs are client supplied.
- Current state: source committed and fetch-verifiable; migration not applied; SQL not executed; worker/events/RTC handoff absent; no integration/runtime test.
- Do not call matching “implemented/complete” until worker, authorized event delivery, cancellation races, queue expiry, session creation and two-account tests pass.
