-- VibeMingle disposable local Supabase smoke tests.
-- Run only after `supabase db reset` on LOCAL Supabase (never production).
-- These assertions verify schema/grants. RLS identity tests require seeded auth.users
-- and authenticated JWT contexts; those are documented in the integration runbook.

do $$
begin
  if to_regclass('public.profiles') is null then raise exception 'profiles missing'; end if;
  if to_regclass('public.match_sessions') is null then raise exception 'match_sessions missing'; end if;
  if to_regclass('public.match_queue') is null then raise exception 'match_queue missing'; end if;
  if to_regclass('public.user_blocks') is null then raise exception 'user_blocks missing'; end if;
  if to_regclass('public.user_reports') is null then raise exception 'user_reports missing'; end if;
  if to_regclass('public.admin_roles') is null then raise exception 'admin_roles missing'; end if;
  if to_regclass('public.user_sanctions') is null then raise exception 'user_sanctions missing'; end if;
  if to_regclass('public.moderation_audit_log') is null then raise exception 'moderation_audit_log missing'; end if;
  if to_regclass('public.api_rate_limits') is null then raise exception 'api_rate_limits missing'; end if;
  if not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='consume_api_rate_limit') then raise exception 'rate limit RPC missing'; end if;
  if not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='moderation_update_report_with_audit') then raise exception 'audit RPC missing'; end if;
  if not exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='profiles' and c.relrowsecurity) then raise exception 'profiles RLS disabled'; end if;
  if not exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='user_reports' and c.relrowsecurity) then raise exception 'reports RLS disabled'; end if;
  if has_function_privilege('anon','public.consume_api_rate_limit(text,integer,integer)','EXECUTE') then raise exception 'anon can execute rate limit RPC'; end if;
  if has_function_privilege('authenticated','public.consume_api_rate_limit(text,integer,integer)','EXECUTE') then raise exception 'authenticated can execute rate limit RPC'; end if;
  if not has_function_privilege('service_role','public.consume_api_rate_limit(text,integer,integer)','EXECUTE') then raise exception 'service_role cannot execute rate limit RPC'; end if;
end $$;
