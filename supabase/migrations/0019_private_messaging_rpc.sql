-- VibeMingle 0019: transactional messaging operations.
-- Every RPC derives actor from auth.uid(); callers cannot supply sender identity.
create or replace function public.conversation_open(p_friend uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_actor uuid:=auth.uid(); v_a uuid; v_b uuid; v_id uuid;
begin
 if v_actor is null then raise exception using errcode='28000',message='authentication required'; end if;
 if p_friend is null or p_friend=v_actor then raise exception using errcode='22023',message='invalid friend'; end if;
 if not exists(select 1 from public.friendships f where f.user_a=least(v_actor,p_friend) and f.user_b=greatest(v_actor,p_friend)) then
   raise exception using errcode='42501',message='friendship required';
 end if;
 if exists(select 1 from public.user_blocks b where (b.blocker_id=v_actor and b.blocked_id=p_friend) or (b.blocker_id=p_friend and b.blocked_id=v_actor)) then
   raise exception using errcode='42501',message='blocked';
 end if;
 v_a:=least(v_actor,p_friend); v_b:=greatest(v_actor,p_friend);
 insert into public.conversations(user_a,user_b) values(v_a,v_b)
 on conflict(user_a,user_b) do update set updated_at=public.conversations.updated_at returning id into v_id;
 insert into public.conversation_members(conversation_id,user_id) values(v_id,v_a),(v_id,v_b) on conflict do nothing;
 return v_id;
end; $$;

create or replace function public.message_send(p_conversation uuid,p_body text)
returns public.messages language plpgsql security definer set search_path=public as $$
declare v_actor uuid:=auth.uid(); v_row public.messages%rowtype; v_conv public.conversations%rowtype; v_peer uuid;
begin
 if v_actor is null then raise exception using errcode='28000',message='authentication required'; end if;
 if p_body is null or char_length(btrim(p_body)) not between 1 and 4000 then raise exception using errcode='22023',message='invalid message body'; end if;
 select * into v_conv from public.conversations c where c.id=p_conversation and exists(select 1 from public.conversation_members m where m.conversation_id=c.id and m.user_id=v_actor);
 if not found then raise exception using errcode='42501',message='conversation unavailable'; end if;
 v_peer:=case when v_conv.user_a=v_actor then v_conv.user_b else v_conv.user_a end;
 if exists(select 1 from public.user_blocks b where (b.blocker_id=v_actor and b.blocked_id=v_peer) or (b.blocker_id=v_peer and b.blocked_id=v_actor)) then raise exception using errcode='42501',message='blocked'; end if;
 insert into public.messages(conversation_id,sender_id,body) values(p_conversation,v_actor,btrim(p_body)) returning * into v_row;
 update public.conversations set updated_at=now() where id=p_conversation;
 return v_row;
end; $$;

create or replace function public.message_edit(p_message uuid,p_body text)
returns public.messages language plpgsql security definer set search_path=public as $$
declare v_actor uuid:=auth.uid(); v_row public.messages%rowtype;
begin
 if v_actor is null then raise exception using errcode='28000',message='authentication required'; end if;
 if p_body is null or char_length(btrim(p_body)) not between 1 and 4000 then raise exception using errcode='22023',message='invalid message body'; end if;
 update public.messages set body=btrim(p_body),edited_at=now() where id=p_message and sender_id=v_actor and deleted_at is null returning * into v_row;
 if not found then raise exception using errcode='42501',message='message unavailable'; end if;
 return v_row;
end; $$;

create or replace function public.message_delete(p_message uuid)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_actor uuid:=auth.uid(); v_count integer;
begin
 if v_actor is null then raise exception using errcode='28000',message='authentication required'; end if;
 update public.messages set body='[deleted]',deleted_at=now(),edited_at=null where id=p_message and sender_id=v_actor and deleted_at is null;
 get diagnostics v_count=row_count; return v_count=1;
end; $$;

create or replace function public.conversation_mark_read(p_conversation uuid)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_actor uuid:=auth.uid(); v_count integer;
begin
 if v_actor is null then raise exception using errcode='28000',message='authentication required'; end if;
 update public.conversation_members set last_read_at=now() where conversation_id=p_conversation and user_id=v_actor;
 get diagnostics v_count=row_count; return v_count=1;
end; $$;

revoke all on function public.conversation_open(uuid) from public,anon;
revoke all on function public.message_send(uuid,text) from public,anon;
revoke all on function public.message_edit(uuid,text) from public,anon;
revoke all on function public.message_delete(uuid) from public,anon;
revoke all on function public.conversation_mark_read(uuid) from public,anon;
grant execute on function public.conversation_open(uuid) to authenticated;
grant execute on function public.message_send(uuid,text) to authenticated;
grant execute on function public.message_edit(uuid,text) to authenticated;
grant execute on function public.message_delete(uuid) to authenticated;
grant execute on function public.conversation_mark_read(uuid) to authenticated;
