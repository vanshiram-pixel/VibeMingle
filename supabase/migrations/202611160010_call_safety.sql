-- Enforce block relationships consistently for friend acceptance and call signaling.
create or replace function public.friend_accept(p_friend uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_me uuid:=auth.uid(); v_low uuid; v_high uuid;
begin
 if v_me is null then raise exception 'authentication required' using errcode='28000'; end if;
 if p_friend is null or p_friend=v_me then raise exception 'invalid friend' using errcode='22023'; end if;
 if exists(select 1 from public.user_blocks where (blocker_id=v_me and blocked_id=p_friend) or (blocker_id=p_friend and blocked_id=v_me)) then raise exception 'user blocked' using errcode='42501'; end if;
 v_low:=least(v_me,p_friend); v_high:=greatest(v_me,p_friend);
 update public.friendships set status='accepted',updated_at=now()
 where user_low=v_low and user_high=v_high and status='pending' and requested_by<>v_me;
 if not found then raise exception 'request not found or accept denied' using errcode='42501'; end if;
end; $$;

create or replace function public.call_request_create(p_callee uuid,p_type text)
returns uuid language plpgsql security definer set search_path=public as $$
declare me uuid:=auth.uid(); cid uuid;
begin
 if me is null then raise exception 'authentication required' using errcode='28000'; end if;
 if p_callee is null or p_callee=me then raise exception 'invalid callee'; end if;
 if p_type not in ('audio','video') then raise exception 'invalid call type'; end if;
 if exists(select 1 from public.user_blocks where (blocker_id=me and blocked_id=p_callee) or (blocker_id=p_callee and blocked_id=me)) then raise exception 'user blocked'; end if;
 if not exists(select 1 from public.friendships f where f.status='accepted'
  and f.user_low=least(me,p_callee) and f.user_high=greatest(me,p_callee)) then
  raise exception 'calls require an accepted friendship';
 end if;
 if exists(select 1 from public.call_requests c where c.status in ('ringing','accepted')
  and (c.caller_id=me or c.callee_id=me or c.caller_id=p_callee or c.callee_id=p_callee)
  and c.created_at>now()-interval '2 minutes') then
  raise exception 'one of the users is already receiving or making a call';
 end if;
 insert into public.call_requests(caller_id,callee_id,call_type) values(me,p_callee,p_type) returning id into cid;
 return cid;
end $$;

create or replace function public.call_request_respond(p_call uuid,p_accept boolean)
returns text language plpgsql security definer set search_path=public as $$
declare me uuid:=auth.uid(); st text; v_caller uuid;
begin
 if me is null then raise exception 'authentication required' using errcode='28000'; end if;
 select caller_id into v_caller from public.call_requests where id=p_call and callee_id=me and status='ringing';
 if v_caller is null then raise exception 'call request not found or expired'; end if;
 if exists(select 1 from public.user_blocks where (blocker_id=me and blocked_id=v_caller) or (blocker_id=v_caller and blocked_id=me)) then raise exception 'user blocked'; end if;
 update public.call_requests set status=case when p_accept then 'accepted' else 'rejected' end,
  responded_at=now()
 where id=p_call and callee_id=me and status='ringing' and created_at>now()-interval '2 minutes'
 returning status into st;
 if st is null then raise exception 'call request not found or expired'; end if;
 return st;
end $$;
