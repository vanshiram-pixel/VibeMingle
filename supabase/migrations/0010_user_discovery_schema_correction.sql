-- VibeMingle 0010: correct discovery projection against foundation schema.
-- Private profiles are not discoverable; sanctions filtering is enforced in later API guards.
drop function if exists public.user_discover(text,integer);
create function public.user_discover(p_query text default '',p_limit integer default 20)
returns table(user_id uuid,display_name text,avatar_path text)
language sql security definer set search_path=''
as $$
 select p.id,p.display_name,p.avatar_path
 from public.profiles p
 where auth.uid() is not null and p.id<>auth.uid()
   and p.visibility<>'private'
   and coalesce(p.display_name,'') ilike '%'||left(trim(coalesce(p_query,'')),64)||'%'
   and not exists(select 1 from public.user_blocks b
      where (b.blocker_id=auth.uid() and b.blocked_id=p.id)
         or (b.blocker_id=p.id and b.blocked_id=auth.uid()))
 order by p.display_name asc
 limit greatest(1,least(coalesce(p_limit,20),30));
$$;
revoke all on function public.user_discover(text,integer) from public,anon;
grant execute on function public.user_discover(text,integer) to authenticated;
