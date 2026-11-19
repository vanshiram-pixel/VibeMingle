# Call backend setup checklist

1. Create/link the intended Supabase project and confirm Auth is enabled.
2. Review `supabase/migrations/0001_call_sessions.sql` in a staging project.
3. Apply migration using Supabase CLI or SQL editor; verify table, indexes, RLS and RPC grants.
4. Add friendship/blocked-user/privacy checks to `call_start` before production (current migration only authenticates the caller and rejects self-calls).
5. Add rate limits, abuse controls, maximum ringing duration, cleanup of stale sessions, and server-side push notification dispatch.
6. Configure private Realtime channel authorization so only call participants can receive their own call events. Keep SDP/ICE ephemeral; do not persist or log payloads.
7. Configure TURN with short-lived server-issued credentials and test relay-only network paths.
8. Run SQL tests for participant isolation, unauthorized transitions, duplicate active calls, terminal state immutability and concurrent call races.
9. Add Flutter app scaffold/dependencies, wire repository/media controller, then test two authenticated devices (audio, video, permissions denied, network changes, hangup, decline, timeout).
10. Production release requires security review, privacy policy, reporting/blocking, rate limiting and verified store permissions.

The migration is a foundation—not a complete production calling backend. Its duplicate-call check should be replaced with a concurrency-safe reservation/locking strategy before launch.
