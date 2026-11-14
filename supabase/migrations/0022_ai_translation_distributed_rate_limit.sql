-- Shared, atomic per-user AI translation rate limit for multi-instance/serverless APIs.
-- Store only counters and timestamps; no translation content or IP addresses.
create table if not exists public.ai_translation_rate_limits (
 user_id uuid primary key references auth.users(id) on delete cascade,
 window_started_at timestamptz not null default now(),
 requests integer not null default 0 check (requests >= 0),
 updated_at timestamptz not null default now()
);
alter table public.ai_translation_rate_limits enable row level security;
revoke all on public.ai_translation_rate_limits from anon, authenticated;
grant all on public.ai_translation_rate_limits to service_role;

create or replace function public.consume_ai_translation_rate_limit(p_user_id uuid)
returns boolean language plpgsql security definer set search_path=public as $$
declare affected integer;
begin
 insert into public.ai_translation_rate_limits(user_id,window_started_at,requests)
 values(p_user_id,now(),1)
 on conflict(user_id) do update set
  window_started_at=case
   when public.ai_translation_rate_limits.window_started_at <= now()-interval '60 seconds' then now()
   else public.ai_translation_rate_limits.window_started_at end,
  requests=case
   when public.ai_translation_rate_limits.window_started_at <= now()-interval '60 seconds' then 1
   else public.ai_translation_rate_limits.requests+1 end,
  updated_at=now()
 where public.ai_translation_rate_limits.window_started_at <= now()-interval '60 seconds'
    or public.ai_translation_rate_limits.requests < 8;
 get diagnostics affected = row_count;
 return affected = 1;
end; $$;
revoke all on function public.consume_ai_translation_rate_limit(uuid) from public,anon,authenticated;
grant execute on function public.consume_ai_translation_rate_limit(uuid) to service_role;
