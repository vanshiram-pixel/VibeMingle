-- Admin/moderation foundation. Admin membership must be provisioned by trusted operators only.
create table if not exists public.admin_members (
 user_id uuid primary key references auth.users(id) on delete cascade,
 role text not null default 'moderator' check(role in ('moderator','admin','super_admin')),
 granted_by uuid references auth.users(id) on delete set null,
 granted_at timestamptz not null default now()
);
alter table public.admin_members enable row level security;
revoke all on public.admin_members from anon,authenticated;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.admin_members where user_id=auth.uid())
$$;
revoke execute on function public.is_admin() from public,anon;
grant execute on function public.is_admin() to authenticated;

create table if not exists public.moderation_actions (
 id uuid primary key default gen_random_uuid(),
 admin_id uuid not null references auth.users(id) on delete restrict,
 report_id uuid references public.user_reports(id) on delete set null,
 target_user uuid references auth.users(id) on delete set null,
 action text not null check(action in ('dismiss_report','warn_user','suspend_user','unsuspend_user','remove_content','note')),
 reason text not null default '',
 created_at timestamptz not null default now()
);
create index if not exists moderation_actions_recent_idx on public.moderation_actions(created_at desc);
alter table public.moderation_actions enable row level security;
drop policy if exists moderation_actions_admin_read on public.moderation_actions;
create policy moderation_actions_admin_read on public.moderation_actions for select to authenticated using(public.is_admin());
revoke insert,update,delete on public.moderation_actions from anon,authenticated;

create or replace function public.moderation_record_action(p_report uuid,p_target uuid,p_action text,p_reason text default '')
returns uuid language plpgsql security definer set search_path=public as $$
declare me uuid:=auth.uid(); aid uuid;
begin
 if me is null or not public.is_admin() then raise exception 'admin access required' using errcode='42501'; end if;
 if p_action not in ('dismiss_report','warn_user','suspend_user','unsuspend_user','remove_content','note') then raise exception 'invalid moderation action' using errcode='22023'; end if;
 insert into public.moderation_actions(admin_id,report_id,target_user,action,reason)
 values(me,p_report,p_target,p_action,left(coalesce(p_reason,''),1000)) returning id into aid;
 return aid;
end $$;
revoke execute on function public.moderation_record_action(uuid,uuid,text,text) from public,anon;
grant execute on function public.moderation_record_action(uuid,uuid,text,text) to authenticated;
