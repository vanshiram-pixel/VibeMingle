-- Account deletion requests are queued for verified admin processing.
create table if not exists public.account_deletion_requests (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 status text not null default 'pending' check(status in ('pending','processing','completed','cancelled')),
 requested_at timestamptz not null default now(),
 processed_at timestamptz,
 );
create unique index if not exists account_deletion_active_user_idx
 on public.account_deletion_requests(user_id) where status in ('pending','processing');
alter table public.account_deletion_requests enable row level security;
drop policy if exists account_deletion_requests_owner_read on public.account_deletion_requests;
create policy account_deletion_requests_owner_read on public.account_deletion_requests
 for select to authenticated using(user_id=auth.uid());
revoke insert,update,delete on public.account_deletion_requests from anon,authenticated;
grant select on public.account_deletion_requests to authenticated;
create or replace function public.account_deletion_request()
returns uuid language plpgsql security definer set search_path=public as $$
declare me uuid:=auth.uid(); rid uuid;
begin
 if me is null then raise exception 'authentication required' using errcode='28000'; end if;
 if exists(select 1 from public.account_deletion_requests where user_id=me and status in ('pending','processing')) then
  raise exception 'deletion request already active';
 end if;
 insert into public.account_deletion_requests(user_id) values(me) returning id into rid;
 return rid;
end $$;
revoke execute on function public.account_deletion_request() from public,anon;
grant execute on function public.account_deletion_request() to authenticated;
