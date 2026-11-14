-- VibeMingle foundation schema (migration 0001)
-- Scope: identity/profile/consent/block/report primitives.
-- Review required before production. No service-role access from clients.

create extension if not exists pgcrypto;

create schema if not exists private;

-- Stable identity is the Supabase Auth UUID; never link by email.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'VibeMingle User'
    check (char_length(display_name) between 1 and 40),
  bio text not null default '' check (char_length(bio) <= 240),
  avatar_path text,
  preferred_language text not null default 'en'
    check (preferred_language ~ '^[a-z]{2,3}(-[A-Z]{2})?$'),
  interests text[] not null default '{}',
  visibility text not null default 'limited'
    check (visibility in ('public','limited','private')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  purpose text not null check (purpose in (
    'terms','privacy','age_assurance','ai_translation','marketing','analytics'
  )),
  policy_version text not null check (char_length(policy_version) between 1 and 80),
  granted boolean not null,
  recorded_at timestamptz not null default now(),
  withdrawn_at timestamptz,
  metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(metadata) = 'object'),
  constraint consent_withdrawal_consistency
    check (withdrawn_at is null or granted = true)
);
create index if not exists user_consents_user_purpose_time
  on public.user_consents(user_id,purpose,recorded_at desc);

-- Block edges are private. Backend must enforce both directions for matching,
-- private calls, friend requests and messaging.
create table if not exists public.user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  reason_code text,
  primary key (blocker_id,blocked_id),
  check (blocker_id <> blocked_id)
);
create index if not exists user_blocks_blocked_idx on public.user_blocks(blocked_id);

-- Report intake metadata only; evidence is deliberately not stored in this table.
-- Create reports via trusted API after authentication, validation and rate limiting.
create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete restrict,
  reported_user_id uuid not null references auth.users(id) on delete restrict,
  category text not null check (category in (
    'harassment','sexual_content','minor_safety','spam','hate','violence',
    'impersonation','scam','other'
  )),
  description text not null default '' check (char_length(description) <= 2000),
  context_type text not null default 'profile'
    check (context_type in ('profile','call','message','private_call')),
  context_id uuid,
  status text not null default 'submitted'
    check (status in ('submitted','triaged','investigating','actioned','dismissed')),
  created_at timestamptz not null default now(),
  check (reporter_id <> reported_user_id)
);
create index if not exists user_reports_queue_idx on public.user_reports(status,created_at);
create index if not exists user_reports_reporter_idx on public.user_reports(reporter_id,created_at desc);

-- Updated-at helper.
create or replace function private.set_updated_at()
returns trigger language plpgsql set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function private.set_updated_at();

-- Profile row self-access only. Public profile discovery must use a reviewed
-- server/API projection; this policy intentionally does not expose profiles to anon.
alter table public.profiles enable row level security;
alter table public.user_consents enable row level security;
alter table public.user_blocks enable row level security;
alter table public.user_reports enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
for select to authenticated using (id = (select auth.uid()));

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
for insert to authenticated with check (id = (select auth.uid()));

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
for update to authenticated using (id = (select auth.uid()))
with check (id = (select auth.uid()));

-- Consent history: users can read their own entries; writes are server-mediated
-- in production to prevent forged audit history. No client insert/update policy.
drop policy if exists consents_select_own on public.user_consents;
create policy consents_select_own on public.user_consents
for select to authenticated using (user_id = (select auth.uid()));

-- Blocks: users may read and manage only edges they created.
drop policy if exists blocks_select_own on public.user_blocks;
create policy blocks_select_own on public.user_blocks
for select to authenticated using (blocker_id = (select auth.uid()));
drop policy if exists blocks_insert_own on public.user_blocks;
create policy blocks_insert_own on public.user_blocks
for insert to authenticated with check (blocker_id = (select auth.uid()));
drop policy if exists blocks_delete_own on public.user_blocks;
create policy blocks_delete_own on public.user_blocks
for delete to authenticated using (blocker_id = (select auth.uid()));

-- Reports: reporter may read their own receipt/status only. Creation and moderation
-- are trusted-server operations; no client insert/update/delete policies.
drop policy if exists reports_select_own on public.user_reports;
create policy reports_select_own on public.user_reports
for select to authenticated using (reporter_id = (select auth.uid()));

-- Keep public schema grants explicit and minimal; RLS still applies.
grant select, insert, update on public.profiles to authenticated;
grant select on public.user_consents to authenticated;
grant select, insert, delete on public.user_blocks to authenticated;
grant select on public.user_reports to authenticated;
revoke all on public.user_reports from anon;
revoke all on public.user_consents from anon;
revoke all on public.user_blocks from anon;

comment on table public.profiles is 'User-owned profile; discovery projection is server-controlled.';
comment on table public.user_consents is 'Versioned consent history; writes should be trusted-server mediated.';
comment on table public.user_blocks is 'Private directed block edges; backend enforces mutual exclusion.';
comment on table public.user_reports is 'Report receipts and workflow metadata; evidence handled separately.';
