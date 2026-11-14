-- VibeMingle migration 0002: match sessions and server-side eligibility primitives.
-- Review with Supabase advisor and integration tests before production.

create table if not exists public.match_sessions (
 id uuid primary key default gen_random_uuid(),
 participant_a uuid not null references auth.users(id) on delete restrict,
 participant_b uuid not null references auth.users(id) on delete restrict,
 status text not null default 'created' check(status in ('created','active','ended','cancelled','reported')),
 region text,
 created_at timestamptz not null default now(),
 started_at timestamptz,
 ended_at timestamptz,
 end_reason text,
 check(participant_a<>participant_b)
);
create index if not exists match_sessions_a_recent on public.match_sessions(participant_a,created_at desc);
create index if not exists match_sessions_b_recent on public.match_sessions(participant_b,created_at desc);
alter table public.match_sessions enable row level security;
drop policy if exists match_sessions_participant_read on public.match_sessions;
create policy match_sessions_participant_read on public.match_sessions
 for select to authenticated using(auth.uid()=participant_a or auth.uid()=participant_b);
-- No client INSERT/UPDATE/DELETE policies: only trusted service functions may mutate sessions.

-- Single atomic admission guard. Caller must be a trusted server using service role;
-- this function does not itself mint a LiveKit token or prove age assurance.
create or replace function public.matching_eligibility_check(p_user uuid)
returns table(eligible boolean, reason text)
language sql security definer set search_path=''
as $$
 select
  (exists(select 1 from public.profiles p where p.id=p_user)
   and exists(select 1 from public.user_consents c where c.user_id=p_user and c.purpose='terms' and c.granted=true and c.withdrawn_at is null)
   and exists(select 1 from public.user_consents c where c.user_id=p_user and c.purpose='privacy' and c.granted=true and c.withdrawn_at is null)
   and exists(select 1 from public.user_consents c where c.user_id=p_user and c.purpose='age_assurance' and c.granted=true and c.withdrawn_at is null)
   and not exists(select 1 from public.user_blocks b where b.blocker_id=p_user or b.blocked_id=p_user)
  ) as eligible,
  case when not exists(select 1 from public.profiles p where p.id=p_user) then 'profile_missing'
       when not exists(select 1 from public.user_consents c where c.user_id=p_user and c.purpose='terms' and c.granted=true and c.withdrawn_at is null) then 'terms_missing'
       when not exists(select 1 from public.user_consents c where c.user_id=p_user and c.purpose='privacy' and c.granted=true and c.withdrawn_at is null) then 'privacy_missing'
       when not exists(select 1 from public.user_consents c where c.user_id=p_user and c.purpose='age_assurance' and c.granted=true and c.withdrawn_at is null) then 'age_assurance_missing'
       when exists(select 1 from public.user_blocks b where b.blocker_id=p_user or b.blocked_id=p_user) then 'blocked_edge_exists'
       else 'eligible' end as reason;
$$;
revoke all on function public.matching_eligibility_check(uuid) from public,anon,authenticated;
grant execute on function public.matching_eligibility_check(uuid) to service_role;

-- Match creation must check BOTH block directions for candidate pair and eligibility
-- in the same transaction before inserting. This migration intentionally does not
-- expose a client-callable matchmaking RPC.
