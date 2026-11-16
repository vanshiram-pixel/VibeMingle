-- Private WebRTC signaling records; media never traverses the database.
create table if not exists public.call_signals (
 id uuid primary key default gen_random_uuid(),
 call_id uuid not null references public.call_requests(id) on delete cascade,
 sender_id uuid not null references auth.users(id) on delete cascade,
 recipient_id uuid not null references auth.users(id) on delete cascade,
 signal_type text not null check(signal_type in ('offer','answer','ice')),
 payload jsonb not null,
 created_at timestamptz not null default now(),
 constraint call_signals_distinct check(sender_id<>recipient_id)
);
create index if not exists call_signals_call_recent_idx on public.call_signals(call_id,created_at);
alter table public.call_signals enable row level security;
drop policy if exists call_signals_participant_read on public.call_signals;
create policy call_signals_participant_read on public.call_signals for select to authenticated
 using(auth.uid() in(sender_id,recipient_id) and exists(select 1 from public.call_requests c where c.id=call_id and auth.uid() in(c.caller_id,c.callee_id)));
revoke insert,update,delete on public.call_signals from anon,authenticated;
grant select on public.call_signals to authenticated;

create or replace function public.call_signal_send(p_call uuid,p_recipient uuid,p_type text,p_payload jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare me uuid:=auth.uid(); peer uuid; cid uuid;
begin
 if me is null then raise exception 'authentication required' using errcode='28000'; end if;
 if p_type not in ('offer','answer','ice') then raise exception 'invalid signal type' using errcode='22023'; end if;
 if p_payload is null or octet_length(p_payload::text)>12000 then raise exception 'signal payload too large' using errcode='22023'; end if;
 select case when caller_id=me then callee_id else caller_id end into peer
 from public.call_requests where id=p_call and me in(caller_id,callee_id) and status='accepted';
 if peer is null or peer<>p_recipient then raise exception 'accepted call or recipient invalid' using errcode='42501'; end if;
 if exists(select 1 from public.user_blocks where (blocker_id=me and blocked_id=peer) or (blocker_id=peer and blocked_id=me)) then raise exception 'user blocked' using errcode='42501'; end if;
 insert into public.call_signals(call_id,sender_id,recipient_id,signal_type,payload) values(p_call,me,peer,p_type,p_payload) returning id into cid;
 return cid;
end $$;
revoke execute on function public.call_signal_send(uuid,uuid,text,jsonb) from public,anon;
grant execute on function public.call_signal_send(uuid,uuid,text,jsonb) to authenticated;
