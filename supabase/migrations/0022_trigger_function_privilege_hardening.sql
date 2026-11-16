-- V4.1 security hardening: trigger-only SECURITY DEFINER functions must not be callable through PostgREST RPC.
revoke all on function public.handle_new_user_profile() from public, anon, authenticated;
revoke all on function public.match_session_emit_events() from public, anon, authenticated;
