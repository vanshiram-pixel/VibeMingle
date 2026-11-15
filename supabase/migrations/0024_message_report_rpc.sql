-- VibeMingle 0024: authenticated message-report intake.
-- Reported identity/context are derived from the message row, never caller input.
create or replace function public.message_report(
  p_message uuid,
  p_category text,
  p_description text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_message public.messages%rowtype;
  v_peer uuid;
  v_report uuid;
begin
  if v_actor is null then
    raise exception using errcode='28000', message='authentication required';
  end if;
  if p_category not in ('harassment','sexual_content','minor_safety','spam','hate','violence','impersonation','scam','other')
     or p_description is null or char_length(p_description) > 2000 then
    raise exception using errcode='22023', message='invalid report';
  end if;

  select m.* into v_message
  from public.messages m
  join public.conversation_members cm on cm.conversation_id=m.conversation_id
  where m.id=p_message and cm.user_id=v_actor and m.sender_id<>v_actor
    and m.deleted_at is null;
  if not found then
    raise exception using errcode='42501', message='message unavailable';
  end if;

  insert into public.user_reports(
    reporter_id, reported_user_id, category, description, context_type, context_id
  ) values (
    v_actor, v_message.sender_id, p_category, btrim(p_description), 'message', v_message.id
  ) returning id into v_report;
  return v_report;
end;
$$;

revoke all on function public.message_report(uuid,text,text) from public,anon;
grant execute on function public.message_report(uuid,text,text) to authenticated;
