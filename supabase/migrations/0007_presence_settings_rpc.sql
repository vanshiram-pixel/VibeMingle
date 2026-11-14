-- VibeMingle 0007: self-service privacy settings.
create or replace function public.presence_settings_update(p_visibility text,p_show_online boolean)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_user uuid;
begin
 if auth.uid() is null then raise exception 'unauthenticated' using errcode='28000'; end if;
 if p_visibility not in ('everyone','friends','nobody') then raise exception 'invalid_visibility' using errcode='22023'; end if;
 insert into public.presence_settings(user_id,visibility,show_online,updated_at)
 values(auth.uid(),p_visibility,p_show_online,now())
 on conflict(user_id) do update set visibility=excluded.visibility,show_online=excluded.show_online,updated_at=now();
 return jsonb_build_object('visibility',p_visibility,'show_online',p_show_online,'updated',true);
end;
$$;
revoke all on function public.presence_settings_update(text,boolean) from public,anon;
grant execute on function public.presence_settings_update(text,boolean) to authenticated;
