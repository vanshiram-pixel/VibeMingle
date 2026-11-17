-- Secure peer read receipts for private conversations.
-- The caller can only read the other participant's last_read_at for a conversation they belong to.
create or replace function public.conversation_peer_read_at(p_conversation uuid)
returns timestamptz
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_me uuid := auth.uid();
  v_read_at timestamptz;
begin
  if v_me is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.conversation_members
    where conversation_id = p_conversation and user_id = v_me
  ) then
    raise exception 'conversation access denied' using errcode = '42501';
  end if;
  select cm.last_read_at into v_read_at
  from public.conversation_members cm
  where cm.conversation_id = p_conversation and cm.user_id <> v_me
  limit 1;
  return v_read_at;
end;
$$;
revoke execute on function public.conversation_peer_read_at(uuid) from public, anon;
grant execute on function public.conversation_peer_read_at(uuid) to authenticated;
