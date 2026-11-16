-- VibeMingle matchmaking queue and pair-session primitives.
create table if not exists public.matchmaking_queue (
  user_id uuid primary key references auth.users(id) on delete cascade,
  queued_at timestamptz not null default now()
);
create index if not exists matchmaking_queue_time_idx on public.matchmaking_queue(queued_at);
alter table public.matchmaking_queue enable row level security;
revoke all on public.matchmaking_queue from anon,authenticated;

create table if not exists public.match_sessions (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references auth.users(id) on delete cascade,
  user_b uuid not null references auth.users(id) on delete cascade,
  status text not null default 'active' check(status in ('active','ended')),
  created_at timestamptz not null default now(),
  ended_at timestamptz,
  constraint match_sessions_pair check(user_a < user_b),
  constraint match_sessions_unique_active_pair unique(user_a,user_b,created_at)
);
create index if not exists match_sessions_user_recent_idx on public.match_sessions(user_a,created_at desc);
create index if not exists match_sessions_user_b_recent_idx on public.match_sessions(user_b,created_at desc);
alter table public.match_sessions enable row level security;
drop policy if exists match_sessions_participant_read on public.match_sessions;
create policy match_sessions_participant_read on public.match_sessions for select to authenticated
  using(auth.uid() in(user_a,user_b));
revoke insert,update,delete on public.match_sessions from anon,authenticated;
grant select on public.match_sessions to authenticated;

create or replace function public.matchmaking_join()
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  me uuid:=auth.uid();
  other uuid;
  sid uuid;
begin
  if me is null then raise exception 'authentication required' using errcode='28000'; end if;
  -- Serialize pairing so two joiners cannot claim the same waiting account.
  perform pg_advisory_xact_lock(hashtext('vibemingle-matchmaking-global'));
  delete from public.matchmaking_queue where user_id=me;
  select q.user_id into other from public.matchmaking_queue q
    where q.user_id<>me
    order by q.queued_at
    limit 1 for update skip locked;
  if other is null then
    insert into public.matchmaking_queue(user_id) values(me) on conflict(user_id) do update set queued_at=now();
    return jsonb_build_object('status','waiting');
  end if;
  delete from public.matchmaking_queue where user_id=other;
  insert into public.match_sessions(user_a,user_b,status)
    values(least(me,other),greatest(me,other),'active') returning id into sid;
  return jsonb_build_object('status','matched','session_id',sid,'peer_id',other);
end;
$$;

create or replace function public.matchmaking_leave()
returns void language plpgsql security definer set search_path=public as $$
declare me uuid:=auth.uid();
begin
  if me is null then raise exception 'authentication required' using errcode='28000'; end if;
  delete from public.matchmaking_queue where user_id=me;
  update public.match_sessions set status='ended',ended_at=now()
    where status='active' and me in(user_a,user_b);
end;
$$;

revoke execute on function public.matchmaking_join() from public,anon;
revoke execute on function public.matchmaking_leave() from public,anon;
grant execute on function public.matchmaking_join() to authenticated;
grant execute on function public.matchmaking_leave() to authenticated;
