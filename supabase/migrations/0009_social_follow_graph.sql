-- V4.1 social graph extension: one-way follows, independent of friendship.
create table if not exists public.user_follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  followed_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followed_id),
  constraint follow_distinct_users check (follower_id <> followed_id)
);
create index if not exists user_follows_followed_recent on public.user_follows(followed_id,created_at desc);
create index if not exists user_follows_follower_recent on public.user_follows(follower_id,created_at desc);
alter table public.user_follows enable row level security;
revoke all on public.user_follows from anon, authenticated;
grant select on public.user_follows to authenticated;
drop policy if exists follows_visible_to_participants on public.user_follows;
create policy follows_visible_to_participants on public.user_follows for select to authenticated
using (auth.uid()=follower_id or auth.uid()=followed_id);
-- Mutations exclusively via guarded RPCs.
create or replace function public.user_follow(p_user_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 if p_user_id is null or p_user_id=auth.uid() then raise exception 'invalid_user'; end if;
 if exists(select 1 from public.user_blocks b where
  (b.blocker_id=auth.uid() and b.blocked_id=p_user_id) or
  (b.blocker_id=p_user_id and b.blocked_id=auth.uid())) then raise exception 'blocked'; end if;
 insert into public.user_follows(follower_id,followed_id) values(auth.uid(),p_user_id) on conflict do nothing;
 return true;
end $$;
create or replace function public.user_unfollow(p_user_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 delete from public.user_follows where follower_id=auth.uid() and followed_id=p_user_id;
 return found;
end $$;
create or replace function public.user_follow_counts(p_user_id uuid)
returns table(followers bigint,following bigint) language plpgsql stable security definer
set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 if p_user_id<>auth.uid() and exists(select 1 from public.user_blocks b where
  (b.blocker_id=auth.uid() and b.blocked_id=p_user_id) or
  (b.blocker_id=p_user_id and b.blocked_id=auth.uid())) then raise exception 'blocked'; end if;
 return query select
 (select count(*) from public.user_follows f where f.followed_id=p_user_id),
 (select count(*) from public.user_follows f where f.follower_id=p_user_id);
end $$;
revoke all on function public.user_follow(uuid),public.user_unfollow(uuid),public.user_follow_counts(uuid) from public,anon;
grant execute on function public.user_follow(uuid),public.user_unfollow(uuid),public.user_follow_counts(uuid) to authenticated;
