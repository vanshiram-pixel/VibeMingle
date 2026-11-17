-- VibeMingle safety: user blocking and account reports
create table if not exists public.user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint user_blocks_distinct check (blocker_id <> blocked_id)
);
alter table public.user_blocks enable row level security;
drop policy if exists user_blocks_owner_select on public.user_blocks;
create policy user_blocks_owner_select on public.user_blocks for select to authenticated using (blocker_id=auth.uid());
revoke insert,update,delete on public.user_blocks from anon,authenticated;
grant select on public.user_blocks to authenticated;

create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reported_id uuid not null references auth.users(id) on delete cascade,
  category text not null check (category in ('harassment','sexual_content','minor_safety','spam','hate','violence','impersonation','scam','other')),
  description text not null default '',
  created_at timestamptz not null default now(),
  constraint user_reports_distinct check (reporter_id <> reported_id)
);
create index if not exists user_reports_created_idx on public.user_reports(created_at desc);
alter table public.user_reports enable row level security;
drop policy if exists user_reports_reporter_select on public.user_reports;
create policy user_reports_reporter_select on public.user_reports for select to authenticated using (reporter_id=auth.uid());
revoke insert,update,delete on public.user_reports from anon,authenticated;
grant select on public.user_reports to authenticated;

create or replace function public.user_block(p_user uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_me uuid:=auth.uid(); v_low uuid; v_high uuid;
begin
 if v_me is null then raise exception 'authentication required' using errcode='28000'; end if;
 if p_user is null or p_user=v_me then raise exception 'invalid user' using errcode='22023'; end if;
 if not exists(select 1 from auth.users where id=p_user) then raise exception 'user not found' using errcode='22023'; end if;
 insert into public.user_blocks(blocker_id,blocked_id) values(v_me,p_user) on conflict do nothing;
 v_low:=least(v_me,p_user); v_high:=greatest(v_me,p_user);
 delete from public.friendships where user_low=v_low and user_high=v_high;
end; $$;

create or replace function public.user_unblock(p_user uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null then raise exception 'authentication required' using errcode='28000'; end if;
 delete from public.user_blocks where blocker_id=auth.uid() and blocked_id=p_user;
end; $$;

create or replace function public.user_report(p_user uuid,p_category text,p_description text default '')
returns uuid language plpgsql security definer set search_path=public as $$
declare v_me uuid:=auth.uid(); v_id uuid;
begin
 if v_me is null then raise exception 'authentication required' using errcode='28000'; end if;
 if p_user is null or p_user=v_me then raise exception 'invalid user' using errcode='22023'; end if;
 if p_category not in ('harassment','sexual_content','minor_safety','spam','hate','violence','impersonation','scam','other') then raise exception 'invalid report category' using errcode='22023'; end if;
 if not exists(select 1 from auth.users where id=p_user) then raise exception 'user not found' using errcode='22023'; end if;
 insert into public.user_reports(reporter_id,reported_id,category,description)
 values(v_me,p_user,p_category,left(coalesce(p_description,''),1000)) returning id into v_id;
 return v_id;
end; $$;

-- Block either direction before a friend request is created/accepted.
create or replace function public.friend_request(p_friend uuid)
returns text language plpgsql security definer set search_path=public as $$
declare v_me uuid:=auth.uid(); v_low uuid; v_high uuid; v_requester uuid; v_status text;
begin
 if v_me is null then raise exception 'authentication required' using errcode='28000'; end if;
 if p_friend is null or p_friend=v_me then raise exception 'invalid friend' using errcode='22023'; end if;
 if not exists(select 1 from auth.users where id=p_friend) then raise exception 'user not found' using errcode='22023'; end if;
 if exists(select 1 from public.user_blocks where (blocker_id=v_me and blocked_id=p_friend) or (blocker_id=p_friend and blocked_id=v_me)) then raise exception 'user blocked' using errcode='42501'; end if;
 v_low:=least(v_me,p_friend); v_high:=greatest(v_me,p_friend);
 insert into public.friendships(user_low,user_high,requested_by,status) values(v_low,v_high,v_me,'pending') on conflict(user_low,user_high) do nothing;
 select requested_by,status into v_requester,v_status from public.friendships where user_low=v_low and user_high=v_high for update;
 if v_status='accepted' then return 'accepted'; end if;
 if v_requester<>v_me then update public.friendships set status='accepted',updated_at=now() where user_low=v_low and user_high=v_high; return 'accepted'; end if;
 return 'pending';
end; $$;

create or replace function public.conversation_open(p_friend uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_me uuid:=auth.uid(); v_a uuid; v_b uuid; v_id uuid;
begin
 if v_me is null then raise exception 'authentication required' using errcode='28000'; end if;
 if p_friend is null or p_friend=v_me then raise exception 'invalid friend' using errcode='22023'; end if;
 if exists(select 1 from public.user_blocks where (blocker_id=v_me and blocked_id=p_friend) or (blocker_id=p_friend and blocked_id=v_me)) then raise exception 'user blocked' using errcode='42501'; end if;
 v_a:=least(v_me,p_friend); v_b:=greatest(v_me,p_friend);
 if not exists(select 1 from public.friendships where user_low=v_a and user_high=v_b and status='accepted') then raise exception 'accepted friendship required' using errcode='42501'; end if;
 insert into public.conversations(user_a,user_b) values(v_a,v_b) on conflict(user_a,user_b) do update set updated_at=public.conversations.updated_at returning id into v_id;
 insert into public.conversation_members(conversation_id,user_id) values(v_id,v_a),(v_id,v_b) on conflict do nothing;
 return v_id;
end; $$;

create or replace function public.message_send(p_conversation uuid,p_body text)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_me uuid:=auth.uid(); v_peer uuid; v_id uuid;
begin
 if v_me is null then raise exception 'authentication required' using errcode='28000'; end if;
 if p_body is null or char_length(trim(p_body)) not between 1 and 4000 then raise exception 'message must be 1-4000 characters' using errcode='22023'; end if;
 select case when user_a=v_me then user_b else user_a end into v_peer from public.conversations c
 where c.id=p_conversation and v_me in (c.user_a,c.user_b);
 if v_peer is null then raise exception 'conversation access denied' using errcode='42501'; end if;
 if exists(select 1 from public.user_blocks where (blocker_id=v_me and blocked_id=v_peer) or (blocker_id=v_peer and blocked_id=v_me) ) then raise exception 'user blocked' using errcode='42501'; end if;
 if not exists(select 1 from public.conversation_members where conversation_id=p_conversation and user_id=v_me) then raise exception 'conversation access denied' using errcode='42501'; end if;
 insert into public.messages(conversation_id,sender_id,body) values(p_conversation,v_me,trim(p_body)) returning id into v_id;
 update public.conversations set updated_at=now() where id=p_conversation;
 return v_id;
end; $$;

revoke execute on function public.user_block(uuid) from public,anon;
revoke execute on function public.user_unblock(uuid) from public,anon;
revoke execute on function public.user_report(uuid,text,text) from public,anon;
grant execute on function public.user_block(uuid) to authenticated;
grant execute on function public.user_unblock(uuid) to authenticated;
grant execute on function public.user_report(uuid,text,text) to authenticated;
