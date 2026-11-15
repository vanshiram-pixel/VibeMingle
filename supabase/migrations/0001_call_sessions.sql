-- VibeMingle private-call session foundation.
-- Apply only after Supabase project is linked; validate policies against app auth rules.
create extension if not exists pgcrypto;

create table if not exists public.call_sessions (
  id uuid primary key default gen_random_uuid(),
  caller_id uuid not null references auth.users(id) on delete cascade,
  callee_id uuid not null references auth.users(id) on delete cascade,
  call_type text not null check (call_type in ('audio','video')),
  status text not null default 'ringing'
    check (status in ('ringing','accepted','connecting','connected','declined','missed','ended','failed')),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  connected_at timestamptz,
  ended_at timestamptz,
  ended_by uuid references auth.users(id),
  end_reason text,
  constraint call_distinct_participants check (caller_id <> callee_id)
);

create index if not exists call_sessions_caller_created_idx
  on public.call_sessions (caller_id, created_at desc);
create index if not exists call_sessions_callee_created_idx
  on public.call_sessions (callee_id, created_at desc);

alter table public.call_sessions enable row level security;
revoke all on public.call_sessions from anon;
grant select on public.call_sessions to authenticated;
grant insert, update, delete on public.call_sessions to authenticated;

drop policy if exists call_sessions_participant_select on public.call_sessions;
create policy call_sessions_participant_select
  on public.call_sessions for select to authenticated
  using (auth.uid() = caller_id or auth.uid() = callee_id);

-- Mutations are performed through security-definer RPCs; direct client writes blocked.
drop policy if exists call_sessions_no_direct_insert on public.call_sessions;
create policy call_sessions_no_direct_insert
  on public.call_sessions for insert to authenticated with check (false);
drop policy if exists call_sessions_no_direct_update on public.call_sessions;
create policy call_sessions_no_direct_update
  on public.call_sessions for update to authenticated using (false) with check (false);
drop policy if exists call_sessions_no_direct_delete on public.call_sessions;
create policy call_sessions_no_direct_delete
  on public.call_sessions for delete to authenticated using (false);

create or replace function public.call_start(p_callee_id uuid, p_call_type text)
returns public.call_sessions
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_call public.call_sessions; v_uid uuid:=auth.uid(); v_first text; v_second text;
begin
  if v_uid is null then raise exception 'authentication_required'; end if;
  if p_callee_id is null or p_callee_id = v_uid then raise exception 'invalid_recipient'; end if;
  if p_call_type not in ('audio','video') then raise exception 'invalid_call_type'; end if;

  -- Lock both participant identities in a deterministic order. This prevents
  -- concurrent call_start requests from creating overlapping active calls.
  v_first:=least(v_uid::text,p_callee_id::text); v_second:=greatest(v_uid::text,p_callee_id::text);
  perform pg_advisory_xact_lock(hashtextextended(v_first,0));
  perform pg_advisory_xact_lock(hashtextextended(v_second,0));

  -- Prevent duplicate active calls involving either participant.
  if exists (
    select 1 from public.call_sessions s
    where s.status in ('ringing','accepted','connecting','connected')
      and (s.caller_id in (auth.uid(), p_callee_id)
        or s.callee_id in (auth.uid(), p_callee_id))
  ) then raise exception 'participant_busy'; end if;

  insert into public.call_sessions(caller_id,callee_id,call_type,status)
  values(v_uid,p_callee_id,p_call_type,'ringing')
  returning * into v_call;
  return v_call;
end;
$$;

create or replace function public.call_transition(p_call_id uuid, p_next_status text, p_end_reason text default null)
returns public.call_sessions
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_call public.call_sessions; v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'authentication_required'; end if;
  select * into v_call from public.call_sessions
    where id = p_call_id and (caller_id = v_uid or callee_id = v_uid)
    for update;
  if not found then raise exception 'call_not_found_or_forbidden'; end if;

  if p_next_status not in ('accepted','connecting','connected','declined','missed','ended','failed')
    then raise exception 'invalid_transition'; end if;

  if p_next_status = 'accepted' and (v_call.callee_id <> v_uid or v_call.status <> 'ringing')
    then raise exception 'transition_forbidden'; end if;
  if p_next_status = 'missed' and (v_call.callee_id <> v_uid or v_call.status <> 'ringing')
    then raise exception 'transition_forbidden'; end if;
  if p_next_status = 'connecting' and v_call.status not in ('accepted','connecting')
    then raise exception 'transition_forbidden'; end if;
  if p_next_status = 'connected' and v_call.status not in ('accepted','connecting')
    then raise exception 'transition_forbidden'; end if;
  if p_next_status = 'declined' and (v_call.callee_id <> v_uid or v_call.status <> 'ringing')
    then raise exception 'transition_forbidden'; end if;
  if p_next_status in ('ended','failed') and v_call.status not in ('ringing','accepted','connecting','connected')
    then raise exception 'transition_forbidden'; end if;

  update public.call_sessions set
    status = p_next_status,
    accepted_at = case when p_next_status = 'accepted' then now() else accepted_at end,
    connected_at = case when p_next_status = 'connected' then now() else connected_at end,
    ended_at = case when p_next_status in ('declined','missed','ended','failed') then now() else ended_at end,
    ended_by = case when p_next_status in ('declined','missed','ended','failed') then v_uid else ended_by end,
    end_reason = case when p_next_status in ('declined','missed','ended','failed') then left(coalesce(p_end_reason,p_next_status),120) else end_reason end
  where id = p_call_id returning * into v_call;
  return v_call;
end;
$$;

revoke all on function public.call_start(uuid,text) from public, anon;
revoke all on function public.call_transition(uuid,text,text) from public, anon;
grant execute on function public.call_start(uuid,text) to authenticated;
grant execute on function public.call_transition(uuid,text,text) to authenticated;

-- Realtime publication is intentionally not enabled here. Configure private,
-- participant-authorized signaling channels separately; never expose SDP/ICE publicly.
