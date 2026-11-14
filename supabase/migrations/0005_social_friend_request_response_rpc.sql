-- VibeMingle 0005: atomic friend request response and cancellation.
create or replace function public.friend_request_respond(p_request uuid,p_action text)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_sender uuid; v_receiver uuid; v_status text;
begin
 if auth.uid() is null then raise exception 'unauthenticated' using errcode='28000'; end if;
 if p_action not in ('accept','reject') then raise exception 'invalid_action' using errcode='22023'; end if;
 select sender_id,receiver_id,status into v_sender,v_receiver,v_status
 from public.friend_requests where id=p_request for update;
 if not found or v_receiver<>auth.uid() then raise exception 'request_unavailable' using errcode='42501'; end if;
 if v_status<>'pending' then raise exception 'request_not_pending' using errcode='23505'; end if;
 if exists(select 1 from public.user_blocks where (blocker_id=v_sender and blocked_id=v_receiver) or (blocker_id=v_receiver and blocked_id=v_sender)) then
   update public.friend_requests set status='cancelled',responded_at=now() where id=p_request;
   raise exception 'target_unavailable' using errcode='42501';
 end if;
 if p_action='accept' then
   insert into public.friendships(user_a,user_b) values(least(v_sender,v_receiver),greatest(v_sender,v_receiver)) on conflict do nothing;
   update public.friend_requests set status='accepted',responded_at=now() where id=p_request;
 else
   update public.friend_requests set status='rejected',responded_at=now() where id=p_request;
 end if;
 return jsonb_build_object('id',p_request,'status',case when p_action='accept' then 'accepted' else 'rejected' end);
end;
$$;

create or replace function public.friend_request_cancel(p_request uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_sender uuid; v_status text;
begin
 if auth.uid() is null then raise exception 'unauthenticated' using errcode='28000'; end if;
 select sender_id,status into v_sender,v_status from public.friend_requests where id=p_request for update;
 if not found or v_sender<>auth.uid() then raise exception 'request_unavailable' using errcode='42501'; end if;
 if v_status<>'pending' then raise exception 'request_not_pending' using errcode='23505'; end if;
 update public.friend_requests set status='cancelled',responded_at=now() where id=p_request;
 return jsonb_build_object('id',p_request,'status','cancelled');
end;
$$;

revoke all on function public.friend_request_respond(uuid,text) from public,anon;
revoke all on function public.friend_request_cancel(uuid) from public,anon;
grant execute on function public.friend_request_respond(uuid,text) to authenticated;
grant execute on function public.friend_request_cancel(uuid) to authenticated;
