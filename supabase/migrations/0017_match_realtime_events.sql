-- V4.1 participant-scoped realtime match lifecycle events.
-- Event payloads intentionally contain no profile, location, or signaling secrets.
create table if not exists public.match_session_events (
 id bigint generated always as identity primary key,
 session_id uuid not null references public.match_sessions(id) on delete cascade,
 recipient_id uuid not null references auth.users(id) on delete cascade,
 event_type text not null check(event_type in ('matched','state_changed','ended')),
 state text not null check(state in ('reserved','connecting','active','ended','failed','cancelled')),
 created_at timestamptz not null default clock_timestamp()
);
create index if not exists match_session_events_recipient_time
 on public.match_session_events(recipient_id,created_at desc);
alter table public.match_session_events enable row level security;
revoke all on public.match_session_events from anon,authenticated;
grant select on public.match_session_events to authenticated;
create policy "Participants read own match events"
 on public.match_session_events for select to authenticated
 using(recipient_id=auth.uid());

create or replace function public.match_session_emit_events()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if tg_op='INSERT' then
  insert into public.match_session_events(session_id,recipient_id,event_type,state)
  values(new.id,new.user_a,'matched',new.state),(new.id,new.user_b,'matched',new.state);
 elsif new.state is distinct from old.state then
  insert into public.match_session_events(session_id,recipient_id,event_type,state)
  values(new.id,new.user_a,case when new.state in('ended','failed','cancelled') then 'ended' else 'state_changed' end,new.state),
        (new.id,new.user_b,case when new.state in('ended','failed','cancelled') then 'ended' else 'state_changed' end,new.state);
 end if;
 return new;
end $$;
drop trigger if exists match_session_event_emit on public.match_sessions;
create trigger match_session_event_emit after insert or update of state on public.match_sessions
 for each row execute function public.match_session_emit_events();

-- Event rows are created by the SECURITY DEFINER trigger only; clients cannot forge them.
