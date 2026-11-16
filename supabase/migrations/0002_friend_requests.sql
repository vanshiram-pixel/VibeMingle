-- VibeMingle friend graph + requests foundation.
create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending','accepted','rejected','cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint friend_request_distinct_users check (sender_id <> recipient_id)
);
create unique index if not exists friend_requests_one_pending_direction
  on public.friend_requests(sender_id,recipient_id) where status='pending';
create index if not exists friend_requests_recipient_pending
  on public.friend_requests(recipient_id,created_at desc) where status='pending';

create table if not exists public.friendships (
  user_low uuid not null references auth.users(id) on delete cascade,
  user_high uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_low,user_high),
  constraint friendship_order check (user_low < user_high)
);

create table if not exists public.user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(blocker_id,blocked_id),
  constraint block_distinct_users check (blocker_id <> blocked_id)
);

alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
alter table public.user_blocks enable row level security;
revoke all on public.friend_requests, public.friendships, public.user_blocks from anon;
grant select on public.friend_requests, public.friendships, public.user_blocks to authenticated;
grant insert,update,delete on public.friend_requests, public.friendships, public.user_blocks to authenticated;

drop policy if exists friend_requests_participant_select on public.friend_requests;
create policy friend_requests_participant_select on public.friend_requests for select to authenticated
using (auth.uid()=sender_id or auth.uid()=recipient_id);
drop policy if exists friend_requests_no_direct_insert on public.friend_requests;
create policy friend_requests_no_direct_insert on public.friend_requests for insert to authenticated with check(false);
drop policy if exists friend_requests_no_direct_update on public.friend_requests;
create policy friend_requests_no_direct_update on public.friend_requests for update to authenticated using(false) with check(false);
drop policy if exists friend_requests_no_direct_delete on public.friend_requests;
create policy friend_requests_no_direct_delete on public.friend_requests for delete to authenticated using(false);

drop policy if exists friendships_participant_select on public.friendships;
create policy friendships_participant_select on public.friendships for select to authenticated
using(auth.uid()=user_low or auth.uid()=user_high);
drop policy if exists friendships_no_direct_mutation on public.friendships;
create policy friendships_no_direct_mutation on public.friendships for all to authenticated using(false) with check(false);

drop policy if exists blocks_owner_select on public.user_blocks;
create policy blocks_owner_select on public.user_blocks for select to authenticated using(auth.uid()=blocker_id);
drop policy if exists blocks_no_direct_mutation on public.user_blocks;
create policy blocks_no_direct_mutation on public.user_blocks for all to authenticated using(false) with check(false);

create or replace function public.friend_request_send(p_recipient_id uuid)
returns public.friend_requests language plpgsql security definer
set search_path=public,pg_temp as $$
declare v_req public.friend_requests;
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 if p_recipient_id is null or p_recipient_id=auth.uid() then raise exception 'invalid_recipient'; end if;
 if exists(select 1 from public.user_blocks b where
   (b.blocker_id=auth.uid() and b.blocked_id=p_recipient_id) or
   (b.blocker_id=p_recipient_id and b.blocked_id=auth.uid())) then raise exception 'blocked'; end if;
 if exists(select 1 from public.friendships f where
   f.user_low=least(auth.uid(),p_recipient_id) and f.user_high=greatest(auth.uid(),p_recipient_id)) then
   raise exception 'already_friends'; end if;
 -- If reciprocal pending request exists, accept it atomically.
 select * into v_req from public.friend_requests
 where sender_id=p_recipient_id and recipient_id=auth.uid() and status='pending'
 for update;
 if found then
   update public.friend_requests set status='accepted',responded_at=now() where id=v_req.id returning * into v_req;
   insert into public.friendships(user_low,user_high)
   values(least(auth.uid(),p_recipient_id),greatest(auth.uid(),p_recipient_id))
   on conflict do nothing;
   return v_req;
 end if;
 insert into public.friend_requests(sender_id,recipient_id,status)
 values(auth.uid(),p_recipient_id,'pending') returning * into v_req;
 return v_req;
end $$;

create or replace function public.friend_request_respond(p_request_id uuid,p_accept boolean)
returns public.friend_requests language plpgsql security definer
set search_path=public,pg_temp as $$
declare v_req public.friend_requests;
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 select * into v_req from public.friend_requests where id=p_request_id for update;
 if not found or v_req.recipient_id<>auth.uid() then raise exception 'request_not_found_or_forbidden'; end if;
 if v_req.status<>'pending' then raise exception 'request_not_pending'; end if;
 if exists(select 1 from public.user_blocks b where
   (b.blocker_id=auth.uid() and b.blocked_id=v_req.sender_id) or
   (b.blocker_id=v_req.sender_id and b.blocked_id=auth.uid()) then raise exception 'blocked'; end if;
 update public.friend_requests set status=case when p_accept then 'accepted' else 'rejected' end,
 responded_at=now() where id=p_request_id returning * into v_req;
 if p_accept then
   insert into public.friendships(user_low,user_high)
   values(least(auth.uid(),v_req.sender_id),greatest(auth.uid(),v_req.sender_id))
   on conflict do nothing;
 end if;
 return v_req;
end $$;

create or replace function public.friend_remove(p_friend_id uuid)
returns boolean language plpgsql security definer
set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 delete from public.friendships where user_low=least(auth.uid(),p_friend_id)
 and user_high=greatest(auth.uid(),p_friend_id);
 return found;
end $$;

create or replace function public.user_block(p_user_id uuid)
returns boolean language plpgsql security definer
set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 if p_user_id is null or p_user_id=auth.uid() then raise exception 'invalid_user'; end if;
 insert into public.user_blocks(blocker_id,blocked_id) values(auth.uid(),p_user_id) on conflict do nothing;
 delete from public.friendships where user_low=least(auth.uid(),p_user_id) and user_high=greatest(auth.uid(),p_user_id);
 update public.friend_requests set status='cancelled',responded_at=now()
 where status='pending' and ((sender_id=auth.uid() and recipient_id=p_user_id) or (sender_id=p_user_id and recipient_id=auth.uid()));
 -- End active calls between these users (server-side safety).
 update public.call_sessions set status='ended',ended_at=now(),ended_by=auth.uid(),end_reason='blocked'
 where status in ('ringing','accepted','connecting','connected')
 and ((caller_id=auth.uid() and callee_id=p_user_id) or (caller_id=p_user_id and callee_id=auth.uid()));
 return true;
end $$;

create or replace function public.user_unblock(p_user_id uuid)
returns boolean language plpgsql security definer
set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 delete from public.user_blocks where blocker_id=auth.uid() and blocked_id=p_user_id;
 return found;
end $$;

revoke all on function public.friend_request_send(uuid) from public,anon;
revoke all on function public.friend_request_respond(uuid,boolean) from public,anon;
revoke all on function public.friend_remove(uuid) from public,anon;
revoke all on function public.user_block(uuid) from public,anon;
revoke all on function public.user_unblock(uuid) from public,anon;
grant execute on function public.friend_request_send(uuid),public.friend_request_respond(uuid,boolean),
 public.friend_remove(uuid),public.user_block(uuid),public.user_unblock(uuid) to authenticated;
