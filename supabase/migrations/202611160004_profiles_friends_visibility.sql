-- Allow profile visibility='friends' to accepted connections only.
drop policy if exists "profiles_read_public_or_self" on public.profiles;
drop policy if exists "profiles_read_public_self_or_friends" on public.profiles;
create policy "profiles_read_public_self_or_friends"
  on public.profiles for select to authenticated
  using (
    visibility = 'public'
    or id = (select auth.uid())
    or (
      visibility = 'friends'
      and exists (
        select 1 from public.friendships f
        where f.status = 'accepted'
          and f.user_low = least(id, (select auth.uid()))
          and f.user_high = greatest(id, (select auth.uid()))
      )
    )
  );
