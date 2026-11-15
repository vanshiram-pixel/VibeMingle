-- VibeMingle 0025: private call requests and consented acceptance.
create table if not exists public.call_requests (
 id uuid primary key default gen_random_uuid(),
 caller_id uuid not null references auth.users(id) on delete cascade,
 recipient_id uuid not null references auth.users(id) on delete cascade,
 status text not null default 'pending' check(status in ('pending','accepted','declined','cancelled','expired')),
 session_id uuid references public.match_sessions(id) on delete set null,
 created_at timestamptz not null default now(),
 responded_at timestamptz,
 expires_at timestamptz not null default now()+interval '90 seconds',
 check(caller_id<>recipient_id)
);
create index if not exists call_requests_recipient_pending on public.call_requests(recipient_id,created_at desc) where status='pending';
create index if not exists call_requests_caller_recent on public.call_requests(caller_id,created_at desc);
alter table public.call_requests enable row level security;
drop policy if exists call_requests_participant_read on public.call_requests;
create policy call_requests_participant_read on public.call_requests for select to authenticated using(auth.uid()=caller_id or auth.uid()=recipient_id);
revoke insert,update,delete on public.call_requests from anon,authenticated;

create or replace function public.call_request_create(p_recipient uuid)
returns public.call_requests language plpgsql security definer set search_path=''
as $$
declare v_actor uuid:=auth.uid(); v_req public.call_requests%rowtype;
begin
 if v_actor is null then raise exception using errcode='28000',message='authentication required';end if;
 if p_recipient is null or p_recipient=v_actor then raise exception using errcode='22023',message='invalid recipient';end if;
 if not exists(select 1 from public.profiles where id=p_recipient) then raise exception using errcode='P0002',message='recipient unavailable';end if;
 if exists(select 1 from public.user_blocks b where (b.blocker_id=v_actor and b.blocked_id=p_recipient) or (b.blocker_id=p_recipient and b.blocked_id=v_actor)) then raise exception using errcode='42501',message='blocked pair';end if;
 if not exists(select 1 from public.user_consents c where c.user_id=v_actor and c.purpose='age_assurance' and c.granted and c.withdrawn_at is null)
 or not exists(select 1 from public.user_consents c where c.user_id=p_recipient and c.purpose='age_assurance' and c.granted and c.withdrawn_at is null) then raise exception using errcode='42501',message='age assurance required';end if;
 if exists(select 1 from public.call_requests r where r.caller_id=v_actor and r.recipient_id=p_recipient and r.status='pending' and r.expires_at>now()) then raise exception using errcode='23505',message='request already pending';end if;
 if exists(select 1 from public.call_requests r where r.caller_id=p_recipient and r.recipient_id=v_actor and r.status='pending' and r.expires_at>now()) then raise exception using errcode='23505',message='incoming request already pending';end if;
 insert into public.call_requests(caller_id,recipient_id) values(v_actor,p_recipient) returning * into v_req;return v_req;
end;$$;

create or replace function public.call_request_respond(p_request uuid,p_accept boolean)
returns table(request_id uuid,status text,session_id uuid) language plpgsql security definer set search_path=''
as $$
declare v_actor uuid:=auth.uid(); r public.call_requests%rowtype; v_session uuid;
begin
 if v_actor is null then raise exception using errcode='28000',message='authentication required';end if;
 select * into r from public.call_requests where id=p_request and recipient_id=v_actor for update;
 if not found then raise exception using errcode='42501',message='request unavailable';end if;
 if r.status<>'pending' or r.expires_at<=now() then update public.call_requests set status='expired',responded_at=now() where id=r.id and status='pending';raise exception using errcode='P0001',message='request expired';end if;
 if exists(select 1 from public.user_blocks b where (b.blocker_id=r.caller_id and b.blocked_id=r.recipient_id) or (b.blocker_id=r.recipient_id and b.blocked_id=r.caller_id)) then raise exception using errcode='42501',message='blocked pair';end if;
 if p_accept then
  insert into public.match_sessions(participant_a,participant_b,status) values(r.caller_id,r.recipient_id,'created') returning id into v_session;
  update public.call_requests set status='accepted',session_id=v_session,responded_at=now() where id=r.id;
  return query select r.id,'accepted'::text,v_session;
 else
  update public.call_requests set status='declined',responded_at=now() where id=r.id;
  return query select r.id,'declined'::text,null::uuid;
 end if;
end;$$;

create or replace function public.call_request_cancel(p_request uuid)
returns boolean language plpgsql security definer set search_path=''
as $$
begin update public.call_requests set status='cancelled',responded_at=now() where id=p_request and caller_id=auth.uid() and status='pending';return found;end;$$;

revoke all on function public.call_request_create(uuid) from public,anon;
revoke all on function public.call_request_respond(uuid,boolean) from public,anon;
revoke all on function public.call_request_cancel(uuid) from public,anon;
grant execute on function public.call_request_create(uuid) to authenticated;
grant execute on function public.call_request_respond(uuid,boolean) to authenticated;
grant execute on function public.call_request_cancel(uuid) to authenticated;
