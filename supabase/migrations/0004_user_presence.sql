-- User online status. Presence is intentionally not a precise location/activity feed.
create table if not exists public.user_presence (
 user_id uuid primary key references auth.users(id) on delete cascade,
 state text not null default 'offline' check(state in ('online','away','offline')),
 last_seen_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.user_presence enable row level security;
revoke all on public.user_presence from anon;
grant select on public.user_presence to authenticated;
grant insert,update,delete on public.user_presence to authenticated;
drop policy if exists presence_friends_select on public.user_presence;
create policy presence_friends_select on public.user_presence for select to authenticated
using(user_id=auth.uid() or exists(
 select 1 from public.friendships f where
 (f.user_low=auth.uid() and f.user_high=user_presence.user_id) or
 (f.user_high=auth.uid() and f.user_low=user_presence.user_id)
));
drop policy if exists presence_no_direct_mutation on public.user_presence;
create policy presence_no_direct_mutation on public.user_presence for all to authenticated using(false) with check(false);

create or replace function public.presence_set(p_state text)
returns public.user_presence language plpgsql security definer set search_path=public,pg_temp as $$
declare v public.user_presence;
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 if p_state not in ('online','away','offline') then raise exception 'invalid_presence'; end if;
 insert into public.user_presence(user_id,state,last_seen_at,updated_at)
 values(auth.uid(),p_state,now(),now())
 on conflict(user_id) do update set state=excluded.state,
 last_seen_at=case when excluded.state='offline' then now() else user_presence.last_seen_at end,
 updated_at=now() returning * into v;
 return v;
end $$;

create or replace function public.presence_heartbeat()
returns public.user_presence language plpgsql security definer set search_path=public,pg_temp as $$
declare v public.user_presence;
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 insert into public.user_presence(user_id,state,last_seen_at,updated_at)
 values(auth.uid(),'online',now(),now())
 on conflict(user_id) do update set state='online',last_seen_at=now(),updated_at=now()
 returning * into v;
 return v;
end $$;

revoke all on function public.presence_set(text),public.presence_heartbeat() from public,anon;
grant execute on function public.presence_set(text),public.presence_heartbeat() to authenticated;
