create table if not exists public.notification_preferences (
 user_id uuid primary key references auth.users(id) on delete cascade,
 messages_enabled boolean not null default true,
 calls_enabled boolean not null default true,
 friend_requests_enabled boolean not null default true,
 quiet_hours_start time,
 quiet_hours_end time,
 updated_at timestamptz not null default now()
);
create table if not exists public.notifications (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 actor_id uuid references auth.users(id) on delete set null,
 kind text not null check(kind in ('message','incoming_call','friend_request','call_missed','system')),
 title text not null check(char_length(title)<=120),
 body text check(body is null or char_length(body)<=300),
 data jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 read_at timestamptz
);
create index if not exists notifications_user_unread_idx on public.notifications(user_id,created_at desc) where read_at is null;
alter table public.notification_preferences enable row level security;
alter table public.notifications enable row level security;
revoke all on public.notification_preferences,public.notifications from anon;
grant select,insert,update,delete on public.notification_preferences to authenticated;
grant select,update,delete on public.notifications to authenticated;
drop policy if exists notification_preferences_owner on public.notification_preferences;
create policy notification_preferences_owner on public.notification_preferences for all to authenticated
using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists notifications_owner_select on public.notifications;
create policy notifications_owner_select on public.notifications for select to authenticated using(user_id=auth.uid());
drop policy if exists notifications_owner_update on public.notifications;
create policy notifications_owner_update on public.notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists notifications_owner_delete on public.notifications;
create policy notifications_owner_delete on public.notifications for delete to authenticated using(user_id=auth.uid());
drop policy if exists notifications_no_client_insert on public.notifications;
create policy notifications_no_client_insert on public.notifications for insert to authenticated with check(false);

create or replace function public.notification_mark_read(p_notification_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 update public.notifications set read_at=coalesce(read_at,now())
 where id=p_notification_id and user_id=auth.uid();
 return found;
end $$;
revoke all on function public.notification_mark_read(uuid) from public,anon;
grant execute on function public.notification_mark_read(uuid) to authenticated;
