-- VibeMingle 0028: private conversation media bucket with membership-scoped access.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('chat-media','chat-media',false,26214400,array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime','audio/m4a','audio/mp4','audio/mpeg','audio/aac','audio/ogg'])
on conflict(id) do update set public=false,file_size_limit=26214400,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists chat_media_member_read on storage.objects;
create policy chat_media_member_read on storage.objects for select to authenticated
using(bucket_id='chat-media' and exists(select 1 from public.conversation_members cm where cm.conversation_id=((storage.foldername(name))[1])::uuid and cm.user_id=auth.uid()));

drop policy if exists chat_media_member_upload on storage.objects;
create policy chat_media_member_upload on storage.objects for insert to authenticated
with check(bucket_id='chat-media' and (storage.foldername(name))[2]=auth.uid()::text and exists(select 1 from public.conversation_members cm where cm.conversation_id=((storage.foldername(name))[1])::uuid and cm.user_id=auth.uid()));

drop policy if exists chat_media_owner_update on storage.objects;
create policy chat_media_owner_update on storage.objects for update to authenticated
using(bucket_id='chat-media' and (storage.foldername(name))[2]=auth.uid()::text and exists(select 1 from public.conversation_members cm where cm.conversation_id=((storage.foldername(name))[1])::uuid and cm.user_id=auth.uid()))
with check(bucket_id='chat-media' and (storage.foldername(name))[2]=auth.uid()::text);

drop policy if exists chat_media_owner_delete on storage.objects;
create policy chat_media_owner_delete on storage.objects for delete to authenticated
using(bucket_id='chat-media' and (storage.foldername(name))[2]=auth.uid()::text);
