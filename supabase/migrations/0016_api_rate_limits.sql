-- V3 moderation rate limits; review and apply manually.
create table if not exists public.api_rate_limits (
  bucket_key text primary key,
  window_started_at timestamptz not null,
  request_count integer not null default 1,
  updated_at timestamptz not null default now()
);
alter table public.api_rate_limits enable row level security;
revoke all on public.api_rate_limits from anon, authenticated;
grant all on public.api_rate_limits to service_role;

create or replace function public.consume_api_rate_limit(
  p_bucket_key text,
  p_limit integer,
  p_window_seconds integer
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare v_allowed boolean;
begin
  if p_limit < 1 or p_window_seconds < 1 then raise exception 'invalid rate limit'; end if;
  insert into api_rate_limits(bucket_key,window_started_at,request_count,updated_at)
  values(p_bucket_key,now(),1,now())
  on conflict(bucket_key) do update set
    window_started_at=case when api_rate_limits.window_started_at <= now() - make_interval(secs => p_window_seconds) then now() else api_rate_limits.window_started_at end,
    request_count=case when api_rate_limits.window_started_at <= now() - make_interval(secs => p_window_seconds) then 1 else api_rate_limits.request_count+1 end,
    updated_at=now();
  select request_count <= p_limit into v_allowed from api_rate_limits where bucket_key=p_bucket_key;
  return v_allowed;
end;
$$;
revoke all on function public.consume_api_rate_limit(text,integer,integer) from public, anon, authenticated;
grant execute on function public.consume_api_rate_limit(text,integer,integer) to service_role;

-- Periodically remove expired buckets (schedule via Supabase Cron after migration).
