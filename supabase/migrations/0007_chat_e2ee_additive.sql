-- V4.1 additive E2EE message lane. Legacy chat_messages is retained for history;
-- this migration does NOT delete/backfill/relabel legacy plaintext.
-- Apply only in a reviewed staging environment after protocol/client readiness.

create table if not exists public.chat_envelopes (
  id uuid primary key default gen_random_uuid(),
  client_message_id uuid not null,
  conversation_id text not null,
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  ciphertext text not null check (length(ciphertext) between 16 and 65536),
  protocol_version text not null check (length(protocol_version) between 1 and 32),
  key_epoch bigint not null check (key_epoch >= 0),
  created_at timestamptz not null default now(),
  delivered_at timestamptz,
  read_at timestamptz,
  deleted_at timestamptz,
  constraint e2ee_distinct_participants check(sender_id <> recipient_id),
  constraint e2ee_client_idempotency unique(sender_id, client_message_id)
);

create index if not exists chat_envelopes_conversation_created_idx
  on public.chat_envelopes(conversation_id, created_at desc);
create index if not exists chat_envelopes_recipient_unread_idx
  on public.chat_envelopes(recipient_id, created_at) where read_at is null;

alter table public.chat_envelopes enable row level security;
revoke all on public.chat_envelopes from anon, public;
grant select on public.chat_envelopes to authenticated;
drop policy if exists chat_envelopes_participant_select on public.chat_envelopes;
create policy chat_envelopes_participant_select on public.chat_envelopes
  for select to authenticated
  using (auth.uid() = sender_id or auth.uid() = recipient_id);
-- All writes must use guarded RPCs; no direct insert/update/delete grants.
revoke insert, update, delete on public.chat_envelopes from authenticated;

create or replace function public.chat_send_e2ee(
  p_recipient_id uuid,
  p_client_message_id uuid,
  p_ciphertext text,
  p_protocol_version text,
  p_key_epoch bigint
) returns public.chat_envelopes
language plpgsql security definer set search_path=public,pg_temp as $$
declare
  v_uid uuid := auth.uid();
  v_conversation text;
  v_row public.chat_envelopes;
begin
  if v_uid is null then raise exception 'authentication_required'; end if;
  if p_recipient_id is null or p_recipient_id = v_uid then raise exception 'invalid_recipient'; end if;
  if p_client_message_id is null then raise exception 'client_message_id_required'; end if;
  if p_ciphertext is null or length(p_ciphertext) < 16 or length(p_ciphertext) > 65536
    then raise exception 'invalid_ciphertext'; end if;
  if p_protocol_version is null or length(p_protocol_version) not between 1 and 32
    then raise exception 'invalid_protocol_version'; end if;
  if p_key_epoch is null or p_key_epoch < 0 then raise exception 'invalid_key_epoch'; end if;

  if exists(select 1 from public.user_blocks b where
    (b.blocker_id=v_uid and b.blocked_id=p_recipient_id) or
    (b.blocker_id=p_recipient_id and b.blocked_id=v_uid)) then
    raise exception 'blocked';
  end if;
  if not exists(select 1 from public.friendships f where
    f.user_low=least(v_uid,p_recipient_id) and f.user_high=greatest(v_uid,p_recipient_id))
    then raise exception 'friends_only'; end if;

  -- Canonical thread identity is derived on server, never accepted from caller.
  v_conversation := least(v_uid,p_recipient_id)::text || ':' || greatest(v_uid,p_recipient_id)::text;

  insert into public.chat_envelopes(
    client_message_id,conversation_id,sender_id,recipient_id,ciphertext,protocol_version,key_epoch
  ) values (
    p_client_message_id,v_conversation,v_uid,p_recipient_id,p_ciphertext,p_protocol_version,p_key_epoch
  )
  on conflict(sender_id,client_message_id) do update
    set client_message_id=excluded.client_message_id
  returning * into v_row;
  -- Idempotent retry must not be allowed to mutate recipient or ciphertext.
  if v_row.sender_id <> v_uid or v_row.recipient_id <> p_recipient_id
    or v_row.ciphertext <> p_ciphertext or v_row.protocol_version <> p_protocol_version
    or v_row.key_epoch <> p_key_epoch then raise exception 'idempotency_payload_mismatch'; end if;
  return v_row;
end $$;

create or replace function public.chat_e2ee_mark_delivered(p_message_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  update public.chat_envelopes set delivered_at=coalesce(delivered_at,now())
    where id=p_message_id and recipient_id=auth.uid() and deleted_at is null;
  return found;
end $$;

create or replace function public.chat_e2ee_mark_read(p_message_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
  if auth.uid() is null then raise exception 'authentication_required'; end if;
  update public.chat_envelopes set read_at=coalesce(read_at,now()),delivered_at=coalesce(delivered_at,now())
    where id=p_message_id and recipient_id=auth.uid() and deleted_at is null;
  return found;
end $$;

revoke all on function public.chat_send_e2ee(uuid,uuid,text,text,bigint),
  public.chat_e2ee_mark_delivered(uuid),public.chat_e2ee_mark_read(uuid) from public,anon;
grant execute on function public.chat_send_e2ee(uuid,uuid,text,text,bigint),
  public.chat_e2ee_mark_delivered(uuid),public.chat_e2ee_mark_read(uuid) to authenticated;

-- NOTE: Legacy chat_send remains active until the app is migrated and legacy writes
-- are disabled in a coordinated release. Do not claim E2EE while legacy path exists.
