-- VibeMingle moderation operations schema (migration 0015)
-- Review and apply explicitly in Supabase; this file is not auto-applied.
create table if not exists public.admin_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('moderator','admin','superadmin')),
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);
create table if not exists public.user_sanctions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  sanction_type text not null check (sanction_type in ('warning','temporary_suspension','permanent_ban')),
  reason text not null check (char_length(reason) between 3 and 2000),
  starts_at timestamptz not null default now(),
  expires_at timestamptz,
  active boolean not null default true,
  issued_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  check (expires_at is null or expires_at > starts_at)
);
create index if not exists user_sanctions_active_user_idx on public.user_sanctions(user_id,active,expires_at);
create table if not exists public.moderation_audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references auth.users(id),
  action text not null check (char_length(action) between 2 and 100),
  target_user_id uuid references auth.users(id),
  report_id uuid references public.user_reports(id),
  sanction_id uuid references public.user_sanctions(id),
  details jsonb not null default '{}'::jsonb check (jsonb_typeof(details)='object'),
  created_at timestamptz not null default now()
);
create index if not exists moderation_audit_time_idx on public.moderation_audit_log(created_at desc);
alter table public.admin_roles enable row level security;
alter table public.user_sanctions enable row level security;
alter table public.moderation_audit_log enable row level security;
-- No client policies: trusted API/service role only.
revoke all on public.admin_roles, public.user_sanctions, public.moderation_audit_log from anon, authenticated;
