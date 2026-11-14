-- VibeMingle V3: server-only call authorization/lifecycle primitives.
-- Service role only; client JWTs cannot invoke these RPCs.
create or replace function public.call_session_authorize(p_session_id uuid,p_user_id uuid)
returns table(authorized boolean, room_name text, session_status text, reason text)
language plpgsql security definer set search_path=''
as $$
declare s public.match_sessions%rowtype;
begin
 select * into s from public.match_sessions where id=p_session_id;
 if not found then return query select false,null::text,null::text,'session_missing'; return; end if;
 if p_user_id not in (s.participant_a,s.participant_b) then
  return query select false,null::text,s.status,'not_participant'; return;
 end if;
 if s.status not in ('created','active') then
  return query select false,null::text,s.status,'session_not_joinable'; return;
 end if;
 if exists(select 1 from public.user_blocks b where
   (b.blocker_id=s.participant_a and b.blocked_id=s.participant_b) or
   (b.blocker_id=s.participant_b and b.blocked_id=s.participant_a)) then
  return query select false,null::text,s.status,'blocked_pair'; return;
 end if;
 if not exists(select 1 from public.user_consents c where c.user_id=p_user_id and c.purpose='terms' and c.granted and c.withdrawn_at is null)
 or not exists(select 1 from public.user_consents c where c.user_id=p_user_id and c.purpose='privacy' and c.granted and c.withdrawn_at is null)
 or not exists(select 1 from public.user_consents c where c.user_id=p_user_id and c.purpose='age_assurance' and c.granted and c.withdrawn_at is null) then
  return query select false,null::text,s.status,'consent_missing'; return;
 end if;
 return query select true,'vm-'||s.id::text,s.status,'authorized';
end;
$$;
create or replace function public.call_session_mark_active(p_session_id uuid,p_user_id uuid)
returns boolean language plpgsql security definer set search_path=''
as $$
begin
 update public.match_sessions set status='active',started_at=coalesce(started_at,now())
 where id=p_session_id and p_user_id in (participant_a,participant_b) and status in ('created','active');
 return found;
end; $$;
create or replace function public.call_session_leave(p_session_id uuid,p_user_id uuid,p_reason text default 'participant_left')
returns boolean language plpgsql security definer set search_path=''
as $$
begin
 update public.match_sessions set status='ended',ended_at=now(),end_reason=left(coalesce(p_reason,'participant_left'),80)
 where id=p_session_id and p_user_id in (participant_a,participant_b) and status in ('created','active');
 return found;
end; $$;
revoke all on function public.call_session_authorize(uuid,uuid) from public,anon,authenticated;
revoke all on function public.call_session_mark_active(uuid,uuid) from public,anon,authenticated;
revoke all on function public.call_session_leave(uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.call_session_authorize(uuid,uuid) to service_role;
grant execute on function public.call_session_mark_active(uuid,uuid) to service_role;
grant execute on function public.call_session_leave(uuid,uuid,text) to service_role;
