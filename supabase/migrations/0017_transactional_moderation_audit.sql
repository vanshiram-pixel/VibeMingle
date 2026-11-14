-- Atomic moderation mutations: state change and audit row commit or roll back together.
create or replace function public.moderation_update_report_with_audit(
 p_report_id uuid, p_status text, p_actor_id uuid
) returns jsonb language plpgsql security definer set search_path=public as $$
declare v_report public.user_reports%rowtype;
begin
 if p_status not in ('triaged','investigating','actioned','dismissed') then raise exception 'invalid report status'; end if;
 update public.user_reports set status=p_status where id=p_report_id returning * into v_report;
 if not found then raise exception 'report not found'; end if;
 insert into public.moderation_audit_log(actor_id,action,target_user_id,report_id,details)
 values(p_actor_id,'report_'||p_status,v_report.reported_user_id,p_report_id,'{}'::jsonb);
 return jsonb_build_object('updated',true,'status',p_status);
end; $$;

create or replace function public.moderation_issue_sanction_with_audit(
 p_user_id uuid,p_type text,p_reason text,p_duration_hours integer,p_actor_id uuid,p_actor_role text
) returns jsonb language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_exp timestamptz;
begin
 if p_type not in ('warning','temporary_suspension','permanent_ban') then raise exception 'invalid sanction type'; end if;
 if p_type='permanent_ban' and p_actor_role<>'superadmin' then raise exception 'permanent ban requires superadmin'; end if;
 if p_type='temporary_suspension' and p_actor_role not in ('admin','superadmin') then raise exception 'temporary suspension requires admin'; end if;
 if p_type='warning' and p_actor_role not in ('moderator','admin','superadmin') then raise exception 'warning requires moderator'; end if;
 if p_type='temporary_suspension' then
   if p_duration_hours is null or p_duration_hours<1 or p_duration_hours>8760 then raise exception 'invalid duration'; end if;
   v_exp=now()+make_interval(hours=>p_duration_hours);
 elsif p_type='permanent_ban' then v_exp=null;
 end if;
 insert into public.user_sanctions(user_id,sanction_type,reason,starts_at,expires_at,active,issued_by)
 values(p_user_id,p_type,p_reason,now(),v_exp,true,p_actor_id) returning id into v_id;
 insert into public.moderation_audit_log(actor_id,action,target_user_id,sanction_id,details)
 values(p_actor_id,'sanction_'||p_type,p_user_id,v_id,jsonb_build_object('durationHours',p_duration_hours));
 return jsonb_build_object('issued',true,'id',v_id,'type',p_type);
end; $$;

create or replace function public.moderation_revoke_sanction_with_audit(
 p_sanction_id uuid,p_actor_id uuid
) returns jsonb language plpgsql security definer set search_path=public as $$
declare v_row public.user_sanctions%rowtype;
begin
 update public.user_sanctions set active=false where id=p_sanction_id and active=true returning * into v_row;
 if not found then raise exception 'active sanction not found'; end if;
 insert into public.moderation_audit_log(actor_id,action,target_user_id,sanction_id,details)
 values(p_actor_id,'sanction_revoked',v_row.user_id,v_row.id,'{}'::jsonb);
 return jsonb_build_object('revoked',true,'id',v_row.id);
end; $$;

revoke all on function public.moderation_update_report_with_audit(uuid,text,uuid) from public,anon,authenticated;
revoke all on function public.moderation_issue_sanction_with_audit(uuid,text,text,integer,uuid,text) from public,anon,authenticated;
revoke all on function public.moderation_revoke_sanction_with_audit(uuid,uuid) from public,anon,authenticated;
grant execute on function public.moderation_update_report_with_audit(uuid,text,uuid) to service_role;
grant execute on function public.moderation_issue_sanction_with_audit(uuid,text,text,integer,uuid,text) to service_role;
grant execute on function public.moderation_revoke_sanction_with_audit(uuid,uuid) to service_role;
