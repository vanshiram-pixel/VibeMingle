-- AI translation consent and privacy-preserving usage accounting.
create table if not exists public.ai_translation_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null check (provider in ('openai')),
  input_chars integer not null check (input_chars between 1 and 4000),
  output_chars integer not null check (output_chars between 0 and 8000),
  created_at timestamptz not null default now()
);
create index if not exists ai_translation_usage_user_time on public.ai_translation_usage(user_id,created_at desc);
alter table public.ai_translation_usage enable row level security;
revoke all on public.ai_translation_usage from anon,authenticated;
grant all on public.ai_translation_usage to service_role;
comment on table public.ai_translation_usage is 'AI translation metering only; never stores translated or source text.';