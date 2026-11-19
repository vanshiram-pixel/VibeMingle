-- V4.1 matching cancellation, stale queue cleanup and service-worker reservation primitives.
create or replace function public.match_queue_leave()
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid(); v_n integer;
begin
 if v_uid is null then raise exception 'authentication_required'; end if;
 delete from public.match_queue where user_id=v_uid and queue_state='waiting';
 get diagnostics v_n=row_count;
 return v_n>0;
end $$;

create or replace function public.match_queue_heartbeat()
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid();
begin
 if v_uid is null then raise exception 'authentication_required'; end if;
 update public.match_queue set heartbeat_at=clock_timestamp()
 where user_id=v_uid and queue_state='waiting';
 return found;
end $$;

-- Worker-only reservation RPC. It accepts no peer identity from client and
-- requires service role; service role must validate both users/preferences/blocks.
create or replace function public.match_reserve_pair(p_user_a uuid,p_user_b uuid,p_session_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare v_a public.match_queue; v_b public.match_queue; v_now timestamptz:=clock_timestamp();
begin
 if coalesce(auth.role(),'')<>'service_role' then raise exception 'service_role_required'; end if;
 if p_user_a is null or p_user_b is null or p_user_a=p_user_b or p_session_id is null then raise exception 'invalid_pair'; end if;
 select * into v_a from public.match_queue where user_id=p_user_a and queue_state='waiting' and heartbeat_at>v_now-interval '30 seconds' for update;
 if not found then return false; end if;
 select * into v_b from public.match_queue where user_id=p_user_b and queue_state='waiting' and heartbeat_at>v_now-interval '30 seconds' for update;
 if not found then return false; end if;
 if exists(select 1 from public.user_blocks b where (b.blocker_id=p_user_a and b.blocked_id=p_user_b) or (b.blocker_id=p_user_b and b.blocked_id=p_user_a)) then return false; end if;
 if exists(select 1 from public.call_sessions s where s.status in ('ringing','accepted','connecting','connected') and (s.caller_id in (p_user_a,p_user_b) or s.callee_id in (p_user_a,p_user_b))) then return false; end if;
 if exists(select 1 from public.match_pair_cooldowns c where c.user_low=least(p_user_a,p_user_b) and c.user_high=greatest(p_user_a,p_user_b) and c.last_matched_at>v_now-interval '24 hours') then return false; end if;
 -- Bilateral age/gender/language/interests matching is deliberately mandatory.
 if (v_a.age_band is not null and (select p.age_band from public.profiles p where p.id=p_user_b)<>v_a.age_band)
 or (v_b.age_band is not null and (select p.age_band from public.profiles p where p.id=p_user_a)<>v_b.age_band)
 or (v_a.gender_preference<>'any' and (select p.gender from public.profiles p where p.id=p_user_b)<>v_a.gender_preference)
 or (v_b.gender_preference<>'any' and (select p.gender from public.profiles p where p.id=p_user_a)<>v_b.gender_preference)
 or (cardinality(v_a.languages)>0 and not exists(select 1 from public.profiles p where p.id=p_user_b and p.languages && v_a.languages))
 or (cardinality(v_b.languages)>0 and not exists(select 1 from public.profiles p where p.id=p_user_a and p.languages && v_b.languages))
 or (cardinality(v_a.interests)>0 and not exists(select 1 from public.profiles p where p.id=p_user_b and p.interests && v_a.interests))
 or (cardinality(v_b.interests)>0 and not exists(select 1 from public.profiles p where p.id=p_user_a and p.interests && v_b.interests)) then return false; end if;
 update public.match_queue set queue_state='reserved' where user_id in(p_user_a,p_user_b);
 insert into public.call_sessions(id,caller_id,callee_id,call_type,status)
 values(p_session_id,p_user_a,p_user_b,'video','accepted');
 insert into public.match_pair_cooldowns(user_low,user_high,last_matched_at)
 values(least(p_user_a,p_user_b),greatest(p_user_a,p_user_b),v_now)
 on conflict(user_low,user_high) do update set last_matched_at=excluded.last_matched_at;
 delete from public.match_queue where user_id in(p_user_a,p_user_b);
 return true;
exception when unique_violation then return false;
end $$;
revoke all on function public.match_reserve_pair(uuid,uuid,uuid) from public,anon,authenticated;
grant execute on function public.match_reserve_pair(uuid,uuid,uuid) to service_role;
