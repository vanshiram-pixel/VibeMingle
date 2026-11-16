-- VibeMingle V4.1 baseline messaging schema
-- Migration: 202611160001_core_messaging.sql
-- NOTE: body is plaintext in this baseline. This migration does NOT implement E2EE.

create extension if not exists pgcrypto;

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references auth.users(id) on delete cascade,
  user_b uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint conversations_distinct_users check (user_a <> user_b),
  constraint conversations_pair_order check (user_a < user_b),
  constraint conversations_pair_unique unique (user_a, user_b)
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  last_read_at timestamptz,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz,
  constraint messages_body_length check (char_length(body) between 1 and 4000)
);

create index if not exists messages_conversation_created_idx
  on public.messages(conversation_id, created_at desc);
create index if not exists conversation_members_user_idx
  on public.conversation_members(user_id, last_read_at desc);

create table if not exists public.message_reports (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  category text not null check (category in
    ('harassment','sexual_content','minor_safety','spam','hate','violence','impersonation','scam','other')),
  description text not null default '',
  created_at timestamptz not null default now(),
  unique (message_id, reporter_id)
);

alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.message_reports enable row level security;

drop policy if exists conversations_member_select on public.conversations;
create policy conversations_member_select on public.conversations
  for select to authenticated using (
    exists (select 1 from public.conversation_members cm
      where cm.conversation_id = conversations.id and cm.user_id = auth.uid())
  );

drop policy if exists conversation_members_self_select on public.conversation_members;
create policy conversation_members_self_select on public.conversation_members
  for select to authenticated using (user_id = auth.uid());

drop policy if exists messages_member_select on public.messages;
create policy messages_member_select on public.messages
  for select to authenticated using (
    exists (select 1 from public.conversation_members cm
      where cm.conversation_id = messages.conversation_id and cm.user_id = auth.uid())
  );

drop policy if exists reports_reporter_select on public.message_reports;
create policy reports_reporter_select on public.message_reports
  for select to authenticated using (reporter_id = auth.uid());

-- No direct client writes: mutations are performed by narrowly scoped RPCs.
revoke insert, update, delete on public.conversations from anon, authenticated;
revoke insert, update, delete on public.conversation_members from anon, authenticated;
revoke insert, update, delete on public.messages from anon, authenticated;
revoke insert, update, delete on public.message_reports from anon, authenticated;
grant select on public.conversations, public.conversation_members, public.messages to authenticated;
grant select on public.message_reports to authenticated;

create or replace function public.conversation_open(p_friend uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_a uuid;
  v_b uuid;
  v_id uuid;
begin
  if v_me is null then raise exception 'authentication required' using errcode = '28000'; end if;
  if p_friend is null or p_friend = v_me then raise exception 'invalid friend' using errcode = '22023'; end if;
  if not exists (select 1 from auth.users where id = p_friend) then
    raise exception 'user not found' using errcode = '22023';
  end if;
  v_a := least(v_me, p_friend);
  v_b := greatest(v_me, p_friend);
  insert into public.conversations(user_a,user_b) values(v_a,v_b)
    on conflict (user_a,user_b) do update set updated_at = public.conversations.updated_at
    returning id into v_id;
  insert into public.conversation_members(conversation_id,user_id)
    values(v_id,v_a),(v_id,v_b) on conflict do nothing;
  return v_id;
end;
$$;

create or replace function public.conversation_mark_read(p_conversation uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'authentication required' using errcode = '28000'; end if;
  update public.conversation_members set last_read_at = now()
   where conversation_id = p_conversation and user_id = auth.uid();
  if not found then raise exception 'conversation access denied' using errcode = '42501'; end if;
end;
$$;

create or replace function public.message_send(p_conversation uuid, p_body text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'authentication required' using errcode = '28000'; end if;
  if p_body is null or char_length(trim(p_body)) not between 1 and 4000 then
    raise exception 'message must be 1-4000 characters' using errcode = '22023';
  end if;
  if not exists (select 1 from public.conversation_members
      where conversation_id = p_conversation and user_id = auth.uid()) then
    raise exception 'conversation access denied' using errcode = '42501';
  end if;
  insert into public.messages(conversation_id,sender_id,body)
    values(p_conversation,auth.uid(),trim(p_body)) returning id into v_id;
  update public.conversations set updated_at = now() where id = p_conversation;
  return v_id;
end;
$$;

create or replace function public.message_edit(p_message uuid, p_body text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'authentication required' using errcode = '28000'; end if;
  if p_body is null or char_length(trim(p_body)) not between 1 and 4000 then
    raise exception 'message must be 1-4000 characters' using errcode = '22023';
  end if;
  update public.messages set body = trim(p_body), edited_at = now()
   where id = p_message and sender_id = auth.uid() and deleted_at is null
     and exists (select 1 from public.conversation_members cm
       where cm.conversation_id = messages.conversation_id and cm.user_id = auth.uid());
  if not found then raise exception 'message not found or edit denied' using errcode = '42501'; end if;
end;
$$;

create or replace function public.message_delete(p_message uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'authentication required' using errcode = '28000'; end if;
  update public.messages set body = '', deleted_at = now()
   where id = p_message and sender_id = auth.uid() and deleted_at is null
     and exists (select 1 from public.conversation_members cm
       where cm.conversation_id = messages.conversation_id and cm.user_id = auth.uid());
  if not found then raise exception 'message not found or delete denied' using errcode = '42501'; end if;
end;
$$;

create or replace function public.message_report(p_message uuid, p_category text, p_description text default '')
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare v_report uuid;
begin
  if auth.uid() is null then raise exception 'authentication required' using errcode = '28000'; end if;
  if p_category not in ('harassment','sexual_content','minor_safety','spam','hate','violence','impersonation','scam','other') then
    raise exception 'invalid report category' using errcode = '22023';
  end if;
  if not exists (select 1 from public.messages m
      join public.conversation_members cm on cm.conversation_id = m.conversation_id
      where m.id = p_message and cm.user_id = auth.uid() and m.sender_id <> auth.uid()) then
    raise exception 'message not found or report denied' using errcode = '42501';
  end if;
  insert into public.message_reports(message_id,reporter_id,category,description)
    values(p_message,auth.uid(),p_category,left(coalesce(p_description,''),1000))
    returning id into v_report;
  return v_report;
end;
$$;

revoke execute on function public.conversation_open(uuid) from public, anon;
revoke execute on function public.conversation_mark_read(uuid) from public, anon;
revoke execute on function public.message_send(uuid,text) from public, anon;
revoke execute on function public.message_edit(uuid,text) from public, anon;
revoke execute on function public.message_delete(uuid) from public, anon;
revoke execute on function public.message_report(uuid,text,text) from public, anon;
grant execute on function public.conversation_open(uuid) to authenticated;
grant execute on function public.conversation_mark_read(uuid) to authenticated;
grant execute on function public.message_send(uuid,text) to authenticated;
grant execute on function public.message_edit(uuid,text) to authenticated;
grant execute on function public.message_delete(uuid) to authenticated;
grant execute on function public.message_report(uuid,text,text) to authenticated;
