-- VibeMingle 0027: reply links in messages.
alter table public.messages add column if not exists reply_to_message uuid references public.messages(id) on delete set null;
create index if not exists messages_reply_to_idx on public.messages(reply_to_message) where reply_to_message is not null;
create or replace function public.message_send(p_conversation uuid,p_body text,p_reply_to uuid default null)
returns public.messages language plpgsql security definer set search_path=public as $$
declare v_actor uuid:=auth.uid(); v_row public.messages%rowtype; v_conv public.conversations%rowtype; v_peer uuid;
begin
 if v_actor is null then raise exception using errcode='28000',message='authentication required'; end if;
 if p_body is null or char_length(btrim(p_body)) not between 1 and 4000 then raise exception using errcode='22023',message='invalid message body'; end if;
 select * into v_conv from public.conversations c where c.id=p_conversation and exists(select 1 from public.conversation_members m where m.conversation_id=c.id and m.user_id=v_actor);
 if not found then raise exception using errcode='42501',message='conversation unavailable'; end if;
 v_peer:=case when v_conv.user_a=v_actor then v_conv.user_b else v_conv.user_a end;
 if exists(select 1 from public.user_blocks b where (b.blocker_id=v_actor and b.blocked_id=v_peer) or (b.blocker_id=v_peer and b.blocked_id=v_actor)) then raise exception using errcode='42501',message='blocked'; end if;
 if p_reply_to is not null and not exists(select 1 from public.messages m where m.id=p_reply_to and m.conversation_id=p_conversation) then raise exception using errcode='22023',message='invalid reply target'; end if;
 insert into public.messages(conversation_id,sender_id,body,reply_to_message) values(p_conversation,v_actor,btrim(p_body),p_reply_to) returning * into v_row;
 update public.conversations set updated_at=now() where id=p_conversation;
 return v_row;
end; $$;
revoke all on function public.message_send(uuid,text,uuid) from public,anon;
grant execute on function public.message_send(uuid,text,uuid) to authenticated;
