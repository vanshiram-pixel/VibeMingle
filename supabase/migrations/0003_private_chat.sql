-- VibeMingle private chat message foundation
create table if not exists public.chat_messages (
 id uuid primary key default gen_random_uuid(),
 conversation_id uuid not null,
 sender_id uuid not null references auth.users(id) on delete cascade,
 recipient_id uuid not null references auth.users(id) on delete cascade,
 body text not null check (char_length(body) between 1 and 4000),
 message_type text not null default 'text' check(message_type in ('text','image','file')),
 created_at timestamptz not null default now(),
 edited_at timestamptz,
 deleted_at timestamptz,
 delivered_at timestamptz,
 read_at timestamptz,
 constraint message_distinct_users check(sender_id<>recipient_id)
);
create index if not exists chat_messages_conversation_created_idx on public.chat_messages(conversation_id,created_at desc);
create index if not exists chat_messages_recipient_unread_idx on public.chat_messages(recipient_id,created_at) where read_at is null;

alter table public.chat_messages enable row level security;
revoke all on public.chat_messages from anon;
grant select on public.chat_messages to authenticated;
grant insert,update,delete on public.chat_messages to authenticated;
drop policy if exists chat_messages_participant_select on public.chat_messages;
create policy chat_messages_participant_select on public.chat_messages for select to authenticated
using(auth.uid()=sender_id or auth.uid()=recipient_id);
drop policy if exists chat_messages_no_direct_insert on public.chat_messages;
create policy chat_messages_no_direct_insert on public.chat_messages for insert to authenticated with check(false);
drop policy if exists chat_messages_no_direct_update on public.chat_messages;
create policy chat_messages_no_direct_update on public.chat_messages for update to authenticated using(false) with check(false);
drop policy if exists chat_messages_no_direct_delete on public.chat_messages;
create policy chat_messages_no_direct_delete on public.chat_messages for delete to authenticated using(false);

create or replace function public.chat_send(p_recipient_id uuid,p_body text,p_conversation_id uuid default null)
returns public.chat_messages language plpgsql security definer set search_path=public,pg_temp as $$
declare v_message public.chat_messages; v_conversation uuid;
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 if p_recipient_id is null or p_recipient_id=auth.uid() then raise exception 'invalid_recipient'; end if;
 if p_body is null or length(trim(p_body))=0 or char_length(p_body)>4000 then raise exception 'invalid_message'; end if;
 if exists(select 1 from public.user_blocks b where
   (b.blocker_id=auth.uid() and b.blocked_id=p_recipient_id) or
   (b.blocker_id=p_recipient_id and b.blocked_id=auth.uid()) then raise exception 'blocked'; end if;
 if not exists(select 1 from public.friendships f where
   f.user_low=least(auth.uid(),p_recipient_id) and f.user_high=greatest(auth.uid(),p_recipient_id)) then
   raise exception 'friends_only'; end if;
 v_conversation:=coalesce(p_conversation_id,least(auth.uid(),p_recipient_id)::text||':'||greatest(auth.uid(),p_recipient_id)::text)::uuid;
 insert into public.chat_messages(conversation_id,sender_id,recipient_id,body)
 values(v_conversation,auth.uid(),p_recipient_id,trim(p_body)) returning * into v_message;
 return v_message;
end $$;

create or replace function public.chat_mark_delivered(p_message_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 update public.chat_messages set delivered_at=coalesce(delivered_at,now())
 where id=p_message_id and recipient_id=auth.uid() and deleted_at is null;
 return found;
end $$;

create or replace function public.chat_mark_read(p_message_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 update public.chat_messages set read_at=coalesce(read_at,now()),delivered_at=coalesce(delivered_at,now())
 where id=p_message_id and recipient_id=auth.uid() and deleted_at is null;
 return found;
end $$;

create or replace function public.chat_edit(p_message_id uuid,p_body text)
returns public.chat_messages language plpgsql security definer set search_path=public,pg_temp as $$
declare v public.chat_messages;
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 if p_body is null or length(trim(p_body))=0 or char_length(p_body)>4000 then raise exception 'invalid_message'; end if;
 update public.chat_messages set body=trim(p_body),edited_at=now()
 where id=p_message_id and sender_id=auth.uid() and deleted_at is null and created_at>now()-interval '15 minutes'
 returning * into v;
 if not found then raise exception 'message_not_editable'; end if;
 return v;
end $$;

create or replace function public.chat_delete(p_message_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 update public.chat_messages set body='Message deleted',deleted_at=now()
 where id=p_message_id and sender_id=auth.uid() and deleted_at is null;
 return found;
end $$;

revoke all on function public.chat_send(uuid,text,uuid),public.chat_mark_delivered(uuid),
 public.chat_mark_read(uuid),public.chat_edit(uuid,text),public.chat_delete(uuid) from public,anon;
grant execute on function public.chat_send(uuid,text,uuid),public.chat_mark_delivered(uuid),
 public.chat_mark_read(uuid),public.chat_edit(uuid,text),public.chat_delete(uuid) to authenticated;
