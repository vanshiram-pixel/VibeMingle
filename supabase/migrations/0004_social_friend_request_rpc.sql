-- VibeMingle 0004: trusted friend request transaction.
-- SECURITY DEFINER RPC; only authenticated callers, sender always auth.uid().
create or replace function public.friend_request_create(p_target uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_id uuid; v_status text;
begin
 if auth.uid() is null then raise exception 'unauthenticated' using errcode='28000'; end if;
 if p_target=auth.uid() then raise exception 'self_request' using errcode='22023'; end if;
 if not exists(select 1 from public.profiles where id=p_target) then raise exception 'target_unavailable' using errcode='22023'; end if;
 if exists(select 1 from public.user_blocks where (blocker_id=auth.uid() and blocked_id=p_target) or (blocker_id=p_target and blocked_id=auth.uid())) then raise exception 'target_unavailable' using errcode='42501'; end if;
 if exists(select 1 from public.friendships where user_a=least(auth.uid(),p_target) and user_b=greatest(auth.uid(),p_target)) then raise exception 'already_friends' using errcode='23505'; end if;
 if exists(select 1 from public.friend_requests where status='pending' and ((sender_id=auth.uid() and receiver_id=p_target) or (sender_id=p_target and receiver_id=auth.uid()))) then raise exception 'request_pending' using errcode='23505'; end if;
 insert into public.friend_requests(sender_id,receiver_id) values(auth.uid(),p_target) returning id,status into v_id,v_status;
 return jsonb_build_object('id',v_id,'status',v_status);
end;
$$;
revoke all on function public.friend_request_create(uuid) from public,anon;
grant execute on function public.friend_request_create(uuid) to authenticated;
