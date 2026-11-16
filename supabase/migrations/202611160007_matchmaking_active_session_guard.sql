-- Idempotent join: preserve an already-active match instead of creating duplicates.
create or replace function public.matchmaking_join()
returns jsonb language plpgsql security definer set search_path=public as $$
declare
  me uuid:=auth.uid();
  other uuid;
  sid uuid;
begin
  if me is null then raise exception 'authentication required' using errcode='28000'; end if;
  perform pg_advisory_xact_lock(hashtext('vibemingle-matchmaking-global'));

  -- A user already in an active session must not be paired a second time.
  select s.id, case when s.user_a=me then s.user_b else s.user_a end
    into sid,other
    from public.match_sessions s
    where s.status='active' and me in(s.user_a,s.user_b)
    order by s.created_at desc limit 1;
  if sid is not null then
    delete from public.matchmaking_queue where user_id=me;
    return jsonb_build_object('status','matched','session_id',sid,'peer_id',other);
  end if;

  delete from public.matchmaking_queue where user_id=me;
  select q.user_id into other from public.matchmaking_queue q
    where q.user_id<>me
    order by q.queued_at limit 1 for update skip locked;
  if other is null then
    insert into public.matchmaking_queue(user_id) values(me)
      on conflict(user_id) do update set queued_at=now();
    return jsonb_build_object('status','waiting');
  end if;
  delete from public.matchmaking_queue where user_id=other;
  insert into public.match_sessions(user_a,user_b,status)
    values(least(me,other),greatest(me,other),'active') returning id into sid;
  return jsonb_build_object('status','matched','session_id',sid,'peer_id',other);
end;
$$;
revoke execute on function public.matchmaking_join() from public,anon;
grant execute on function public.matchmaking_join() to authenticated;
