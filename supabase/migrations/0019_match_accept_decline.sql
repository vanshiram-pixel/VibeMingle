-- V4.1: explicit two-sided match acceptance before call-room connection.
alter table public.match_sessions
  add column if not exists accepted_a_at timestamptz,
  add column if not exists accepted_b_at timestamptz;

create or replace function public.match_session_accept(p_session_id uuid)
returns public.match_sessions language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid(); v_row public.match_sessions;
begin
 if v_uid is null then raise exception 'authentication_required'; end if;
 update public.match_sessions s set
   accepted_a_at=case when s.user_a=v_uid then coalesce(s.accepted_a_at,clock_timestamp()) else s.accepted_a_at end,
   accepted_b_at=case when s.user_b=v_uid then coalesce(s.accepted_b_at,clock_timestamp()) else s.accepted_b_at end,
   state=case
     when coalesce(s.accepted_a_at,case when s.user_a=v_uid then clock_timestamp() end) is not null
      and coalesce(s.accepted_b_at,case when s.user_b=v_uid then clock_timestamp() end) is not null
     then 'connecting'
     else s.state end
 where s.id=p_session_id and v_uid in(s.user_a,s.user_b) and s.state='reserved'
 returning * into v_row;
 if not found then raise exception 'match_not_accepting'; end if;
 return v_row;
end $$;

create or replace function public.match_session_decline(p_session_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid();
begin
 if v_uid is null then raise exception 'authentication_required'; end if;
 update public.match_sessions set state='cancelled',ended_at=clock_timestamp()
 where id=p_session_id and v_uid in(user_a,user_b) and state in('reserved','connecting');
 return found;
end $$;

revoke all on function public.match_session_accept(uuid),public.match_session_decline(uuid) from public,anon;
grant execute on function public.match_session_accept(uuid),public.match_session_decline(uuid) to authenticated;
