-- VibeMingle 0008: server-mediated online state for friend presence.
create table if not exists public.presence_state(
 user_id uuid primary key references auth.users(id) on delete cascade,
 last_seen_at timestamptz not null default now()
);
alter table public.presence_state enable row level security;
-- No direct client read/write. Only narrowly scoped RPCs expose presence.

create or replace function public.presence_heartbeat()
returns jsonb language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null then raise exception 'unauthenticated' using errcode='28000'; end if;
 insert into public.presence_state(user_id,last_seen_at) values(auth.uid(),now())
 on conflict(user_id) do update set last_seen_at=now();
 return jsonb_build_object('ok',true);
end;
$$;

create or replace function public.friend_list_safe()
returns table(friend_id uuid,display_name text,avatar_path text,created_at timestamptz,
 presence_visibility text,show_online boolean,is_online boolean)
language sql security definer set search_path=''
as $$
 select f.friend_id,f.display_name,f.avatar_path,f.created_at,
        f.presence_visibility,f.show_online,
        (f.show_online and f.presence_visibility in ('everyone','friends')
         and ps.last_seen_at >= now()-interval '90 seconds') as is_online
 from (
   select case when x.user_a=auth.uid() then x.user_b else x.user_a end as friend_id,
          p.display_name,p.avatar_path,x.created_at,
          coalesce(settings.visibility,'friends') as presence_visibility,
          coalesce(settings.show_online,true) as show_online
   from public.friendships x
   join public.profiles p on p.id=case when x.user_a=auth.uid() then x.user_b else x.user_a end
   left join public.presence_settings settings on settings.user_id=p.id
   where auth.uid() is not null
     and (x.user_a=auth.uid() or x.user_b=auth.uid())
     and not exists(select 1 from public.user_blocks b
       where (b.blocker_id=auth.uid() and b.blocked_id=p.id)
          or (b.blocker_id=p.id and b.blocked_id=auth.uid()))
 ) f
 left join public.presence_state ps on ps.user_id=f.friend_id
 order by f.created_at desc;
$$;

revoke all on function public.presence_heartbeat() from public,anon;
grant execute on function public.presence_heartbeat() to authenticated;
revoke all on function public.friend_list_safe() from public,anon;
grant execute on function public.friend_list_safe() to authenticated;
