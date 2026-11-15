-- Publish participant-scoped match events to Supabase Realtime.
-- Idempotent: safe for fresh and already-configured projects.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'match_session_events'
  ) then
    alter publication supabase_realtime add table public.match_session_events;
  end if;
end $$;
