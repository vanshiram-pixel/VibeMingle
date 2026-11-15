-- Hotfix for 0015: keep match_sessions.state inside its declared CHECK constraint.
create or replace function public.match_session_end(p_session_id uuid,p_reason text default 'ended')
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid(); v_state text;
begin
 if v_uid is null then raise exception 'authentication_required'; end if;
 if p_reason not in ('ended','cancelled','failed','blocked','reported') then raise exception 'invalid_end_reason'; end if;
 v_state:=case when p_reason='failed' then 'failed' when p_reason='cancelled' then 'cancelled' else 'ended' end;
 update public.match_sessions set state=v_state,ended_at=clock_timestamp()
 where id=p_session_id and (user_a=v_uid or user_b=v_uid) and state in('reserved','connecting','active');
 return found;
end $$;
revoke all on function public.match_session_end(uuid,text) from public,anon;
grant execute on function public.match_session_end(uuid,text) to authenticated;
