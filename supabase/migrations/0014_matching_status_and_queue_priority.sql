-- Matching status polling without re-enqueueing users or changing queue priority.
create or replace function public.matching_queue_status(p_user uuid)
returns table(status text,session_id uuid,partner_id uuid)
language sql security definer set search_path=''
as $$
 select 'matched'::text,s.id,case when s.participant_a=p_user then s.participant_b else s.participant_a end
 from public.match_sessions s
 where (s.participant_a=p_user or s.participant_b=p_user) and s.status in ('created','active')
 order by s.created_at desc limit 1
 union all
 select 'queued'::text,null::uuid,null::uuid
 where exists(select 1 from public.match_queue q where q.user_id=p_user)
 and not exists(select 1 from public.match_sessions s where (s.participant_a=p_user or s.participant_b=p_user) and s.status in ('created','active'))
 union all
 select 'idle'::text,null::uuid,null::uuid
 where not exists(select 1 from public.match_queue q where q.user_id=p_user)
 and not exists(select 1 from public.match_sessions s where (s.participant_a=p_user or s.participant_b=p_user) and s.status in ('created','active'))
 limit 1;
$$;
revoke all on function public.matching_queue_status(uuid) from public,anon,authenticated;
grant execute on function public.matching_queue_status(uuid) to service_role;

-- Preserve the original waiting timestamp on repeat admissions.
create or replace function public.matching_enqueue_or_pair(p_user uuid,p_preferences jsonb default '{}'::jsonb)
returns table(matched boolean,session_id uuid,partner_id uuid)
language plpgsql security definer set search_path=''
as $$
declare v_candidate uuid; v_session uuid; v_pref jsonb;
begin
 if jsonb_typeof(p_preferences)<>'object' then raise exception 'invalid_preferences'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_user::text,0));
 if not exists(select 1 from public.profiles p where p.id=p_user) then raise exception 'profile_missing'; end if;
 if not exists(select 1 from public.user_consents c where c.user_id=p_user and c.purpose='terms' and c.granted and c.withdrawn_at is null)
 or not exists(select 1 from public.user_consents c where c.user_id=p_user and c.purpose='privacy' and c.granted and c.withdrawn_at is null)
 or not exists(select 1 from public.user_consents c where c.user_id=p_user and c.purpose='age_assurance' and c.granted and c.withdrawn_at is null)
 then raise exception 'consent_required'; end if;
 select q.user_id,q.preferences into v_candidate,v_pref from public.match_queue q
 where q.user_id<>p_user
 and (coalesce(p_preferences->>'region','')='' or coalesce(q.preferences->>'region','')='' or q.preferences->>'region'=p_preferences->>'region')
 and (coalesce(p_preferences->>'language','')='' or coalesce(q.preferences->>'language','')='' or q.preferences->>'language'=p_preferences->>'language')
 and not exists(select 1 from public.user_blocks b where (b.blocker_id=p_user and b.blocked_id=q.user_id) or (b.blocker_id=q.user_id and b.blocked_id=p_user))
 and exists(select 1 from public.profiles p where p.id=q.user_id)
 and exists(select 1 from public.user_consents c where c.user_id=q.user_id and c.purpose='terms' and c.granted and c.withdrawn_at is null)
 and exists(select 1 from public.user_consents c where c.user_id=q.user_id and c.purpose='privacy' and c.granted and c.withdrawn_at is null)
 and exists(select 1 from public.user_consents c where c.user_id=q.user_id and c.purpose='age_assurance' and c.granted and c.withdrawn_at is null)
 order by q.queued_at for update skip locked limit 1;
 if v_candidate is null then
  insert into public.match_queue(user_id,preferences,queued_at) values(p_user,p_preferences,now())
  on conflict(user_id) do update set preferences=excluded.preferences;
  return query select false,null::uuid,null::uuid; return;
 end if;
 if exists(select 1 from public.user_blocks b where (b.blocker_id=p_user and b.blocked_id=v_candidate) or (b.blocker_id=v_candidate and b.blocked_id=p_user)) then return query select false,null::uuid,null::uuid; return; end if;
 insert into public.match_sessions(participant_a,participant_b,status) values(p_user,v_candidate,'created') returning id into v_session;
 delete from public.match_queue where user_id in (p_user,v_candidate);
 return query select true,v_session,v_candidate;
end;
$$;
revoke all on function public.matching_enqueue_or_pair(uuid,jsonb) from public,anon,authenticated;
grant execute on function public.matching_enqueue_or_pair(uuid,jsonb) to service_role;
