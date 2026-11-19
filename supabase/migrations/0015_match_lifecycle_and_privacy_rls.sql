-- V4.1: participant-only match session reads, RPC-only lifecycle, block-aware social visibility.
drop policy if exists match_sessions_participant_read on public.match_sessions;
create policy match_sessions_participant_read on public.match_sessions for select to authenticated
using (auth.uid()=user_a or auth.uid()=user_b);
grant select on public.match_sessions to authenticated;

create or replace function public.match_session_end(p_session_id uuid,p_reason text default 'ended')
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid();
begin
 if v_uid is null then raise exception 'authentication_required'; end if;
 if p_reason not in ('ended','cancelled','failed','blocked','reported') then raise exception 'invalid_end_reason'; end if;
 update public.match_sessions set state=case when p_reason in ('failed','cancelled') then p_reason else 'ended' end,ended_at=clock_timestamp()
 where id=p_session_id and (user_a=v_uid or user_b=v_uid) and state in('reserved','connecting','active');
 return found;
end $$;
revoke all on function public.match_session_end(uuid,text) from public,anon;
grant execute on function public.match_session_end(uuid,text) to authenticated;

-- A block hides follow edges from either involved user and blocks future follows.
drop policy if exists follows_visible_to_participants on public.user_follows;
create policy follows_visible_to_participants on public.user_follows for select to authenticated
using (
 (auth.uid()=follower_id or auth.uid()=followed_id)
 and not exists(select 1 from public.user_blocks b where
  (b.blocker_id=follower_id and b.blocked_id=followed_id)
  or (b.blocker_id=followed_id and b.blocked_id=follower_id)
 )
);

-- Discovery profile reads must respect discoverability and bilateral blocks.
drop policy if exists "Profiles visible to authenticated users" on public.profiles;
drop policy if exists profiles_discoverable_or_self on public.profiles;
create policy profiles_discoverable_or_self on public.profiles for select to authenticated
using (
 id=auth.uid()
 or (discoverable=true and not exists(select 1 from public.user_blocks b where
   (b.blocker_id=auth.uid() and b.blocked_id=id)
   or (b.blocker_id=id and b.blocked_id=auth.uid())))
);
