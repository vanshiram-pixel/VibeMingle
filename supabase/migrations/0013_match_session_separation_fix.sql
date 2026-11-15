-- Correct reservation target: matching is not a private-call acceptance.
create table if not exists public.match_sessions (
 id uuid primary key,
 user_a uuid not null references auth.users(id) on delete cascade,
 user_b uuid not null references auth.users(id) on delete cascade,
 state text not null default 'reserved' check(state in ('reserved','connecting','active','ended','failed','cancelled')),
 created_at timestamptz not null default now(),
 ended_at timestamptz,
 constraint match_session_distinct check(user_a<>user_b)
);
alter table public.match_sessions enable row level security;
revoke all on public.match_sessions from anon,authenticated;
create index if not exists match_sessions_user_a_active on public.match_sessions(user_a,state) where state in ('reserved','connecting','active');
create index if not exists match_sessions_user_b_active on public.match_sessions(user_b,state) where state in ('reserved','connecting','active');

create or replace function public.match_reserve_pair(p_user_a uuid,p_user_b uuid,p_session_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare v_a public.match_queue; v_b public.match_queue; v_now timestamptz:=clock_timestamp();
begin
 if coalesce(auth.role(),'')<>'service_role' then raise exception 'service_role_required'; end if;
 if p_user_a is null or p_user_b is null or p_user_a=p_user_b or p_session_id is null then raise exception 'invalid_pair'; end if;
 -- Matching requires explicit, current consent and service-verified age eligibility.
 if not exists(select 1 from public.match_user_consent c where c.user_id=p_user_a and c.enabled=true)
 or not exists(select 1 from public.match_user_consent c where c.user_id=p_user_b and c.enabled=true)
 or not exists(select 1 from public.match_eligibility e where e.user_id=p_user_a and e.age_verified=true)
 or not exists(select 1 from public.match_eligibility e where e.user_id=p_user_b and e.age_verified=true)
 then return false; end if;
 -- Stable lock order prevents pair reservation deadlocks.
 if p_user_a<p_user_b then
  select * into v_a from public.match_queue where user_id=p_user_a and queue_state='waiting' and heartbeat_at>v_now-interval '30 seconds' for update;
  if not found then return false; end if;
  select * into v_b from public.match_queue where user_id=p_user_b and queue_state='waiting' and heartbeat_at>v_now-interval '30 seconds' for update;
 else
  select * into v_b from public.match_queue where user_id=p_user_b and queue_state='waiting' and heartbeat_at>v_now-interval '30 seconds' for update;
  if not found then return false; end if;
  select * into v_a from public.match_queue where user_id=p_user_a and queue_state='waiting' and heartbeat_at>v_now-interval '30 seconds' for update;
 end if;
 if not found then return false; end if;
 if exists(select 1 from public.user_blocks b where (b.blocker_id=p_user_a and b.blocked_id=p_user_b) or (b.blocker_id=p_user_b and b.blocked_id=p_user_a)) then return false; end if;
 if exists(select 1 from public.call_sessions s where s.status in ('ringing','accepted','connecting','connected') and (s.caller_id in(p_user_a,p_user_b) or s.callee_id in(p_user_a,p_user_b))) or
 exists(select 1 from public.match_sessions m where m.state in('reserved','connecting','active') and (m.user_a in(p_user_a,p_user_b) or m.user_b in(p_user_a,p_user_b))) then return false; end if;
 if exists(select 1 from public.match_pair_cooldowns c where c.user_low=least(p_user_a,p_user_b) and c.user_high=greatest(p_user_a,p_user_b) and c.last_matched_at>v_now-interval '24 hours') then return false; end if;
 if (v_a.age_band is not null and (select p.age_band from public.profiles p where p.id=p_user_b)<>v_a.age_band)
 or (v_b.age_band is not null and (select p.age_band from public.profiles p where p.id=p_user_a)<>v_b.age_band)
 or (v_a.gender_preference<>'any' and (select p.gender from public.profiles p where p.id=p_user_b)<>v_a.gender_preference)
 or (v_b.gender_preference<>'any' and (select p.gender from public.profiles p where p.id=p_user_a)<>v_b.gender_preference)
 or (cardinality(v_a.languages)>0 and not exists(select 1 from public.profiles p where p.id=p_user_b and p.languages && v_a.languages))
 or (cardinality(v_b.languages)>0 and not exists(select 1 from public.profiles p where p.id=p_user_a and p.languages && v_b.languages))
 or (cardinality(v_a.interests)>0 and not exists(select 1 from public.profiles p where p.id=p_user_b and p.interests && v_a.interests))
 or (cardinality(v_b.interests)>0 and not exists(select 1 from public.profiles p where p.id=p_user_a and p.interests && v_b.interests)) then return false; end if;
 update public.match_queue set queue_state='reserved' where user_id in(p_user_a,p_user_b);
 insert into public.match_sessions(id,user_a,user_b,state) values(p_session_id,p_user_a,p_user_b,'reserved');
 insert into public.match_pair_cooldowns(user_low,user_high,last_matched_at) values(least(p_user_a,p_user_b),greatest(p_user_a,p_user_b),v_now)
 on conflict(user_low,user_high) do update set last_matched_at=excluded.last_matched_at;
 delete from public.match_queue where user_id in(p_user_a,p_user_b);
 return true;
exception when unique_violation then return false;
end $$;
revoke all on function public.match_reserve_pair(uuid,uuid,uuid) from public,anon,authenticated;
grant execute on function public.match_reserve_pair(uuid,uuid,uuid) to service_role;
