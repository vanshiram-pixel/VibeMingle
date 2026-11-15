-- VibeMingle 0029: attachment metadata linked to a chat message.
create table if not exists public.message_attachments(
 id uuid primary key default gen_random_uuid(),
 message_id uuid not null unique references public.messages(id) on delete cascade,
 conversation_id uuid not null references public.conversations(id) on delete cascade,
 uploader_id uuid not null references auth.users(id) on delete cascade,
 storage_path text not null unique,
 file_name text not null,
 mime_type text not null,
 byte_size bigint not null check(byte_size between 1 and 26214400),
 media_kind text not null check(media_kind in ('image','video','audio')),
 created_at timestamptz not null default now(),
 check(storage_path like conversation_id::text || '/' || uploader_id::text || '/%')
);
create index if not exists message_attachments_conversation on public.message_attachments(conversation_id,created_at desc);
alter table public.message_attachments enable row level security;
drop policy if exists message_attachments_member_read on public.message_attachments;
create policy message_attachments_member_read on public.message_attachments for select to authenticated
using(exists(select 1 from public.conversation_members cm where cm.conversation_id=message_attachments.conversation_id and cm.user_id=auth.uid()));
drop policy if exists message_attachments_sender_insert on public.message_attachments;
create policy message_attachments_sender_insert on public.message_attachments for insert to authenticated
with check(uploader_id=auth.uid() and exists(select 1 from public.messages m join public.conversation_members cm on cm.conversation_id=m.conversation_id where m.id=message_attachments.message_id and m.conversation_id=message_attachments.conversation_id and m.sender_id=auth.uid() and cm.user_id=auth.uid()));
drop policy if exists message_attachments_uploader_delete on public.message_attachments;
create policy message_attachments_uploader_delete on public.message_attachments for delete to authenticated using(uploader_id=auth.uid());
grant select,insert,delete on public.message_attachments to authenticated;
