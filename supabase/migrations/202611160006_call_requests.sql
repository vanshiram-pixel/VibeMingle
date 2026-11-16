-- Call signaling request lifecycle (media transport is provided by a later WebRTC layer).
create table if not exists public.call_requests (
  id uuid primary key default gen_random_uuid(),
  caller_id uuid not null references auth.users(id) on delete cascade,
  callee_id uuid not null references auth.users(id) on delete cascade,
  call_type text not null check(call_type in ('audio','video')),
  status text not null default 'ringing' check(status in ('ringing','accepted','rejected','cancelled','ended','expired')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  ended_at timestamptz,
  check(caller_id<>callee_id)
);
create index if not exists call_requests_callee_recent_idx on public.call_requests(callee_id,status,created_at desc);
create index if not exists call_requests_caller_recent_idx on public.call_requests(caller_id,status,created_at desc);
alter table public.call_requests enable row level security;
drop policy if exists call_requests_participant_read on public.call_requests;
create policy call_requests_participant_read on public.call_requests for select to authenticated
 using(auth.uid() in(caller_id,callee_id));
revoke insert,update,delete on public.call_requests from anon,authenticated;
grant select on public.call_requests to authenticated;

create or replace function public.call_request_create(p_callee uuid,p_type text)
returns uuid language plpgsql security definer set search_path=public as $$
declare me uuid:=auth.uid(); cid uuid;
begin
 if me is null then raise exception 'authentication required' using errcode='28000'; end if;
 if p_callee is null or p_callee=me then raise exception 'invalid callee'; end if;
 if p_type not in ('audio','video') then raise exception 'invalid call type'; end if;
 if not exists(select 1 from public.friendships f where f.status='accepted'
  and f.user_low=least(me,p_callee) and f.user_high=greatest(me,p_callee)) then
  raise exception 'calls require an accepted friendship';
 end if;
 if exists(select 1 from public.call_requests c where c.status='ringing'
  and (c.caller_id=me or c.callee_id=me or c.caller_id=p_callee or c.callee_id=p_callee)
  and c.created_at>now()-interval '2 minutes') then
  raise exception 'one of the users is already receiving or making a call';
 end if;
 insert into public.call_requests(caller_id,callee_id,call_type) values(me,p_callee,p_type) returning id into cid;
 return cid;
end $$;

create or replace function public.call_request_respond(p_call uuid,p_accept boolean)
returns text language plpgsql security definer set search_path=public as $$
declare me uuid:=auth.uid(); st text;
begin
 if me is null then raise exception 'authentication required' using errcode='28000'; end if;
 update public.call_requests set status=case when p_accept then 'accepted' else 'rejected' end,
  responded_at=now()
 where id=p_call and callee_id=me and status='ringing' and created_at>now()-interval '2 minutes'
 returning status into st;
 if st is null then raise exception 'call request not found or expired'; end if;
 return st;
end $$;

create or replace function public.call_request_cancel(p_call uuid)
returns void language plpgsql security definer set search_path=public as $$
declare me uuid:=auth.uid();
begin
 if me is null then raise exception 'authentication required' using errcode='28000'; end if;
 update public.call_requests set status='cancelled',ended_at=now()
 where id=p_call and caller_id=me and status='ringing';
 if not found then raise exception 'active outgoing call not found'; end if;
end $$;

create or replace function public.call_request_end(p_call uuid)
returns void language plpgsql security definer set search_path=public as $$
declare me uuid:=auth.uid();
begin
 if me is null then raise exception 'authentication required' using errcode='28000'; end if;
 update public.call_requests set status='ended',ended_at=now()
 where id=p_call and me in(caller_id,callee_id) and status='accepted';
 if not found then raise exception 'active call not found'; end if;
end $$;

revoke execute on function public.call_request_create(uuid,text) from public,anon;
revoke execute on function public.call_request_respond(uuid,boolean) from public,anon;
revoke execute on function public.call_request_cancel(uuid) from public,anon;
revoke execute on function public.call_request_end(uuid) from public,anon;
grant execute on function public.call_request_create(uuid,text) to authenticated;
grant execute on function public.call_request_respond(uuid,boolean) to authenticated;
grant execute on function public.call_request_cancel(uuid) to authenticated;
grant execute on function public.call_request_end(uuid) to authenticated;
