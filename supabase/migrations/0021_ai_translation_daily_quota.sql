-- Atomic per-user daily AI translation guard. Counters only; no text stored.
create table if not exists public.ai_translation_daily_quota (
 user_id uuid not null references auth.users(id) on delete cascade,
 quota_date date not null default (timezone('utc', now()))::date,
 requests integer not null default 0 check (requests >= 0),
 input_chars integer not null default 0 check (input_chars >= 0),
 updated_at timestamptz not null default now(),
 primary key(user_id,quota_date)
);
alter table public.ai_translation_daily_quota enable row level security;
revoke all on public.ai_translation_daily_quota from anon, authenticated;
grant all on public.ai_translation_daily_quota to service_role;
create or replace function public.consume_ai_translation_quota(p_user_id uuid,p_input_chars integer)
returns boolean language plpgsql security definer set search_path=public as $$
declare allowed boolean;
begin
 if p_input_chars is null or p_input_chars < 1 or p_input_chars > 4000 then return false; end if;
 insert into public.ai_translation_daily_quota(user_id,quota_date,requests,input_chars)
 values(p_user_id,(timezone('utc',now()))::date,1,p_input_chars)
 on conflict(user_id,quota_date) do update set
  requests=public.ai_translation_daily_quota.requests+1,
  input_chars=public.ai_translation_daily_quota.input_chars+excluded.input_chars,
  updated_at=now()
 where public.ai_translation_daily_quota.requests < 30
 and public.ai_translation_daily_quota.input_chars+p_input_chars <= 30000;
 get diagnostics allowed = row_count;
 return allowed;
end; $$;
revoke all on function public.consume_ai_translation_quota(uuid,integer) from public,anon,authenticated;
grant execute on function public.consume_ai_translation_quota(uuid,integer) to service_role;
