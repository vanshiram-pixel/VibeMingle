-- Global daily AI translation request budget. This limits aggregate provider spend
-- even when many users are individually within their quota. Counts only; no text.
create table if not exists public.ai_translation_global_daily_budget (
 budget_date date primary key,
 requests integer not null default 0 check (requests >= 0),
 updated_at timestamptz not null default now()
);
alter table public.ai_translation_global_daily_budget enable row level security;
revoke all on public.ai_translation_global_daily_budget from anon, authenticated;
grant all on public.ai_translation_global_daily_budget to service_role;

create or replace function public.consume_ai_translation_global_limit(p_daily_limit integer)
returns boolean language plpgsql security definer set search_path=public as $$
declare affected integer;
begin
 if p_daily_limit is null or p_daily_limit < 1 then return false; end if;
 insert into public.ai_translation_global_daily_budget(budget_date,requests)
 values((timezone('utc',now()))::date,1)
 on conflict(budget_date) do update set
  requests=public.ai_translation_global_daily_budget.requests+1,
  updated_at=now()
 where public.ai_translation_global_daily_budget.requests < p_daily_limit;
 get diagnostics affected = row_count;
 return affected = 1;
end; $$;
revoke all on function public.consume_ai_translation_global_limit(integer) from public,anon,authenticated;
grant execute on function public.consume_ai_translation_global_limit(integer) to service_role;
