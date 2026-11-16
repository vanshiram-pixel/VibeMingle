-- VibeMingle V4.1 friend graph and relationship-gated conversations
create table if not exists public.friendships (
  user_low uuid not null references auth.users(id) on delete cascade,
  user_high uuid not null references auth.users(id) on delete cascade,
  requested_by uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_low,user_high),
  constraint friendships_pair_order check (user_low < user_high),
  constraint friendships_requester_member check (requested_by in (user_low,user_high)
));

alter table public.friendships enable row level security;
drop policy if exists friendships_participant_select on public.friendships;
create policy friendships_participant_select on public.friendships
  for select to authenticated using (auth.uid() in (user_low,user_high));
revoke insert,update,delete on public.friendships from anon,authenticated;
grant select on public.friendships to authenticated;

create or replace function public.friend_request(p_friend uuid)
returns text language plpgsql security definer set search_path=public as $$
declare v_me uuid:=auth.uid(); v_low uuid; v_high uuid; v_requester uuid; v_status text;
begin
  if v_me is null then raise exception 'authentication required' using errcode='28000'; end if;
  if p_friend is null or p_friend=v_me then raise exception 'invalid friend' using errcode='22023'; end if;
  if not exists(select 1 from auth.users where id=p_friend) then raise exception 'user not found' using errcode='22023'; end if;
  v_low:=least(v_me,p_friend); v_high:=greatest(v_me,p_friend);
  insert into public.friendships(user_low,user_high,requested_by,status)
    values(v_low,v_high,v_me,'pending')
    on conflict(user_low,user_high) do nothing;
  select requested_by,status into v_requester,v_status from public.friendships
    where user_low=v_low and user_high=v_high for update;
  if v_status='accepted' then return 'accepted'; end if;
  if v_requester<>v_me then
    update public.friendships set status='accepted',updated_at=now()
      where user_low=v_low and user_high=v_high;
    return 'accepted';
  end if;
  return 'pending';
end; $$;

create or replace function public.friend_accept(p_friend uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_me uuid:=auth.uid(); v_low uuid; v_high uuid;
begin
  if v_me is null then raise exception 'authentication required' using errcode='28000'; end if;
  if p_friend is null or p_friend=v_me then raise exception 'invalid friend' using errcode='22023'; end if;
  v_low:=least(v_me,p_friend); v_high:=greatest(v_me,p_friend);
  update public.friendships set status='accepted',updated_at=now()
    where user_low=v_low and user_high=v_high and status='pending' and requested_by<>v_me;
  if not found then raise exception 'request not found or accept denied' using errcode='42501'; end if;
end; $$;

create or replace function public.friend_remove(p_friend uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_me uuid:=auth.uid(); v_low uuid; v_high uuid;
begin
  if v_me is null then raise exception 'authentication required' using errcode='28000'; end if;
  if p_friend is null or p_friend=v_me then raise exception 'invalid friend' using errcode='22023'; end if;
  v_low:=least(v_me,p_friend); v_high:=greatest(v_me,p_friend);
  delete from public.friendships where user_low=v_low and user_high=v_high;
end; $$;

-- A private conversation may only be opened by accepted friends.
create or replace function public.conversation_open(p_friend uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_me uuid:=auth.uid(); v_a uuid; v_b uuid; v_id uuid;
begin
  if v_me is null then raise exception 'authentication required' using errcode='28000'; end if;
  if p_friend is null or p_friend=v_me then raise exception 'invalid friend' using errcode='22023'; end if;
  v_a:=least(v_me,p_friend); v_b:=greatest(v_me,p_friend);
  if not exists(select 1 from public.friendships f where f.user_low=v_a and f.user_high=v_b and f.status='accepted') then
    raise exception 'accepted friendship required' using errcode='42501';
  end if;
  insert into public.conversations(user_a,user_b) values(v_a,v_b)
    on conflict(user_a,user_b) do update set updated_at=public.conversations.updated_at
    returning id into v_id;
  insert into public.conversation_members(conversation_id,user_id)
    values(v_id,v_a),(v_id,v_b) on conflict do nothing;
  return v_id;
end; $$;

revoke execute on function public.friend_request(uuid) from public,anon;
revoke execute on function public.friend_accept(uuid) from public,anon;
revoke execute on function public.friend_remove(uuid) from public,anon;
grant execute on function public.friend_request(uuid) to authenticated;
grant execute on function public.friend_accept(uuid) to authenticated;
grant execute on function public.friend_remove(uuid) to authenticated;
