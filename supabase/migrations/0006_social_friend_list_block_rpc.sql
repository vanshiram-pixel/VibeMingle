-- VibeMingle 0006: safe friend projection, unfriend and block controls.
-- Assumes user_blocks(blocker_id, blocked_id) is defined by the safety schema.
create or replace function public.friend_list_safe()
returns table(friend_id uuid,display_name text,avatar_path text,created_at timestamptz,
 presence_visibility text,show_online boolean)
language sql security definer set search_path=''
as $$
 select case when f.user_a=auth.uid() then f.user_b else f.user_a end,
        p.display_name,p.avatar_path,f.created_at,
        coalesce(ps.visibility,'friends'),coalesce(ps.show_online,true)
 from public.friendships f
 join public.profiles p on p.id=case when f.user_a=auth.uid() then f.user_b else f.user_a end
 left join public.presence_settings ps on ps.user_id=p.id
 where auth.uid() is not null
   and (f.user_a=auth.uid() or f.user_b=auth.uid())
   and not exists(select 1 from public.user_blocks b
      where (b.blocker_id=auth.uid() and b.blocked_id=p.id)
         or (b.blocker_id=p.id and b.blocked_id=auth.uid()))
 order by f.created_at desc;
$$;

create or replace function public.friendship_remove(p_friend uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null then raise exception 'unauthenticated' using errcode='28000'; end if;
 if p_friend=auth.uid() then raise exception 'invalid_target' using errcode='22023'; end if;
 delete from public.friendships where user_a=least(auth.uid(),p_friend) and user_b=greatest(auth.uid(),p_friend);
 if not found then raise exception 'friendship_unavailable' using errcode='42501'; end if;
 return jsonb_build_object('friend_id',p_friend,'removed',true);
end;
$$;

create or replace function public.user_block_create(p_target uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null then raise exception 'unauthenticated' using errcode='28000'; end if;
 if p_target=auth.uid() then raise exception 'invalid_target' using errcode='22023'; end if;
 if not exists(select 1 from auth.users where id=p_target) then raise exception 'target_unavailable' using errcode='22023'; end if;
 insert into public.user_blocks(blocker_id,blocked_id) values(auth.uid(),p_target) on conflict do nothing;
 delete from public.friendships where user_a=least(auth.uid(),p_target) and user_b=greatest(auth.uid(),p_target);
 update public.friend_requests set status='cancelled',responded_at=now()
 where status='pending' and ((sender_id=auth.uid() and receiver_id=p_target) or (sender_id=p_target and receiver_id=auth.uid()));
 return jsonb_build_object('blocked_user_id',p_target,'blocked',true);
end;
$$;

create or replace function public.user_block_remove(p_target uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null then raise exception 'unauthenticated' using errcode='28000'; end if;
 delete from public.user_blocks where blocker_id=auth.uid() and blocked_id=p_target;
 return jsonb_build_object('blocked_user_id',p_target,'blocked',false);
end;
$$;

revoke all on function public.friend_list_safe() from public,anon;
revoke all on function public.friendship_remove(uuid) from public,anon;
revoke all on function public.user_block_create(uuid) from public,anon;
revoke all on function public.user_block_remove(uuid) from public,anon;
grant execute on function public.friend_list_safe() to authenticated;
grant execute on function public.friendship_remove(uuid) to authenticated;
grant execute on function public.user_block_create(uuid) to authenticated;
grant execute on function public.user_block_remove(uuid) to authenticated;
