-- V4.1 public device directory for E2EE session establishment.
-- Private keys/session state NEVER belong in this table.
-- Apply only after review in staging; not applied by this commit.

create table if not exists public.user_devices (
  device_id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  identity_key text not null check (length(identity_key) between 32 and 4096),
  signed_prekey text not null check (length(signed_prekey) between 32 and 4096),
  signed_prekey_signature text not null check (length(signed_prekey_signature) between 32 and 4096),
  protocol_version text not null check (length(protocol_version) between 1 and 32),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  revoked_at timestamptz,
  unique(user_id, device_id)
);
create index if not exists user_devices_active_by_user
  on public.user_devices(user_id, last_seen_at desc) where revoked_at is null;

create table if not exists public.device_one_time_prekeys (
  device_id uuid not null references public.user_devices(device_id) on delete cascade,
  prekey_id bigint not null check(prekey_id > 0),
  public_key text not null check(length(public_key) between 32 and 4096),
  created_at timestamptz not null default now(),
  consumed_at timestamptz,
  primary key(device_id, prekey_id)
);
create index if not exists device_prekeys_available
  on public.device_one_time_prekeys(device_id, prekey_id) where consumed_at is null;

alter table public.user_devices enable row level security;
alter table public.device_one_time_prekeys enable row level security;
revoke all on public.user_devices, public.device_one_time_prekeys from anon, public;
grant select on public.user_devices to authenticated;
-- No direct access to one-time prekeys; consume through RPC.
revoke all on public.device_one_time_prekeys from authenticated;

drop policy if exists user_devices_active_public_select on public.user_devices;
create policy user_devices_active_public_select on public.user_devices
 for select to authenticated using (revoked_at is null);

create or replace function public.e2ee_register_device(
 p_device_id uuid,p_identity_key text,p_signed_prekey text,
 p_signed_prekey_signature text,p_protocol_version text
) returns public.user_devices
language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid(); v public.user_devices;
begin
 if v_uid is null then raise exception 'authentication_required'; end if;
 if p_device_id is null or p_identity_key is null or length(p_identity_key) not between 32 and 4096
 or p_signed_prekey is null or length(p_signed_prekey) not between 32 and 4096
 or p_signed_prekey_signature is null or length(p_signed_prekey_signature) not between 32 and 4096
 or p_protocol_version is null or length(p_protocol_version) not between 1 and 32
 then raise exception 'invalid_device_bundle'; end if;
 -- Device IDs are immutable to an account. Revoked IDs cannot be reactivated.
 if exists(select 1 from public.user_devices d where d.device_id=p_device_id and
   (d.user_id<>v_uid or d.revoked_at is not null)) then raise exception 'device_id_unavailable'; end if;
 insert into public.user_devices(device_id,user_id,identity_key,signed_prekey,
   signed_prekey_signature,protocol_version)
 values(p_device_id,v_uid,p_identity_key,p_signed_prekey,p_signed_prekey_signature,p_protocol_version)
 on conflict(device_id) do update set
   identity_key=excluded.identity_key,signed_prekey=excluded.signed_prekey,
   signed_prekey_signature=excluded.signed_prekey_signature,
   protocol_version=excluded.protocol_version,updated_at=now(),last_seen_at=now()
 where public.user_devices.user_id=v_uid and public.user_devices.revoked_at is null
 returning * into v;
 if not found then raise exception 'device_registration_conflict'; end if;
 return v;
end $$;

create or replace function public.e2ee_revoke_device(p_device_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 update public.user_devices set revoked_at=coalesce(revoked_at,now()),updated_at=now()
 where device_id=p_device_id and user_id=auth.uid();
 if found then
   update public.device_one_time_prekeys set consumed_at=coalesce(consumed_at,now())
    where device_id=p_device_id and consumed_at is null;
 end if;
 return found;
end $$;

create or replace function public.e2ee_publish_prekeys(p_device_id uuid,p_prekeys jsonb)
returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare v_count integer;
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 if jsonb_typeof(p_prekeys)<>'array' or jsonb_array_length(p_prekeys)>100 then
   raise exception 'invalid_prekey_batch'; end if;
 if not exists(select 1 from public.user_devices d where d.device_id=p_device_id
   and d.user_id=auth.uid() and d.revoked_at is null) then raise exception 'device_not_active'; end if;
 insert into public.device_one_time_prekeys(device_id,prekey_id,public_key)
 select p_device_id,(item->>'id')::bigint,item->>'public_key'
 from jsonb_array_elements(p_prekeys) item
 where (item->>'id') ~ '^[1-9][0-9]{0,18}$'
 and length(item->>'public_key') between 32 and 4096
 on conflict(device_id,prekey_id) do nothing;
 get diagnostics v_count=row_count;
 return v_count;
end $$;

-- Atomically returns one recipient device bundle and consumes at most one OTK.
-- This RPC does not verify cryptographic signatures; clients must verify the
-- signed-prekey signature using the selected audited protocol implementation.
create or replace function public.e2ee_claim_bundle(p_recipient_id uuid)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare v_device public.user_devices; v_prekey public.device_one_time_prekeys;
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 if p_recipient_id is null or p_recipient_id=auth.uid() then raise exception 'invalid_recipient'; end if;
 if exists(select 1 from public.user_blocks b where
   (b.blocker_id=auth.uid() and b.blocked_id=p_recipient_id) or
   (b.blocker_id=p_recipient_id and b.blocked_id=auth.uid())) then raise exception 'blocked'; end if;
 if not exists(select 1 from public.friendships f where
   f.user_low=least(auth.uid(),p_recipient_id) and f.user_high=greatest(auth.uid(),p_recipient_id))
 then raise exception 'friends_only'; end if;
 select * into v_device from public.user_devices d
  where d.user_id=p_recipient_id and d.revoked_at is null
  order by d.last_seen_at desc limit 1;
 if not found then raise exception 'recipient_no_active_device'; end if;
 select * into v_prekey from public.device_one_time_prekeys p
  where p.device_id=v_device.device_id and p.consumed_at is null
  order by p.prekey_id for update skip locked limit 1;
 if found then update public.device_one_time_prekeys set consumed_at=now()
   where device_id=v_prekey.device_id and prekey_id=v_prekey.prekey_id; end if;
 return jsonb_build_object('device_id',v_device.device_id,'identity_key',v_device.identity_key,
  'signed_prekey',v_device.signed_prekey,'signed_prekey_signature',v_device.signed_prekey_signature,
  'protocol_version',v_device.protocol_version,
  'one_time_prekey',case when v_prekey.prekey_id is null then null else
    jsonb_build_object('id',v_prekey.prekey_id,'public_key',v_prekey.public_key) end);
end $$;

revoke all on function public.e2ee_register_device(uuid,text,text,text,text),
 public.e2ee_revoke_device(uuid),public.e2ee_publish_prekeys(uuid,jsonb),
 public.e2ee_claim_bundle(uuid) from public,anon;
grant execute on function public.e2ee_register_device(uuid,text,text,text,text),
 public.e2ee_revoke_device(uuid),public.e2ee_publish_prekeys(uuid,jsonb),
 public.e2ee_claim_bundle(uuid) to authenticated;

-- Security review TODO before staging apply:
-- * add strict rate limits / quotas for prekey batches and bundle claims;
-- * verify signatures in client protocol library (server cannot validate arbitrary protocol);
-- * make device list visibility policy relationship-scoped if product privacy requires;
-- * validate SQL behavior and RLS in disposable Supabase staging.
