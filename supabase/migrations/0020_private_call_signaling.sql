-- V4.1 private WebRTC signaling: participant-only, short-lived SDP/ICE exchange.
-- Signals are opaque transport payloads; call authorization remains in call_sessions RPCs.
create table if not exists public.call_signals (
  id bigint generated always as identity primary key,
  call_id uuid not null references public.call_sessions(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('offer','answer','ice','renegotiate','hangup')),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default clock_timestamp(),
  expires_at timestamptz not null default (clock_timestamp()+interval '10 minutes'),
  constraint call_signal_distinct_users check(sender_id<>recipient_id),
  constraint call_signal_payload_size check(octet_length(payload::text)<=65536)
);
create index if not exists call_signals_call_created_idx on public.call_signals(call_id,created_at);
create index if not exists call_signals_expiry_idx on public.call_signals(expires_at);

alter table public.call_signals enable row level security;
revoke all on public.call_signals from anon;
grant select,insert on public.call_signals to authenticated;
drop policy if exists call_signals_participant_read on public.call_signals;
create policy call_signals_participant_read on public.call_signals for select to authenticated
using (auth.uid() in(sender_id,recipient_id) and exists(
 select 1 from public.call_sessions c where c.id=call_id and auth.uid() in(c.caller_id,c.callee_id)
));
drop policy if exists call_signals_authorized_send on public.call_signals;
create policy call_signals_authorized_send on public.call_signals for insert to authenticated
with check (
 sender_id=auth.uid()
 and recipient_id<>auth.uid()
 and expires_at<=clock_timestamp()+interval '10 minutes'
 and expires_at>clock_timestamp()
 and exists(
  select 1 from public.call_sessions c
  where c.id=call_id and auth.uid() in(c.caller_id,c.callee_id)
    and recipient_id=case when c.caller_id=auth.uid() then c.callee_id else c.caller_id end
    and c.status in('accepted','connecting','connected')
 )
);
drop policy if exists call_signals_no_update on public.call_signals;
create policy call_signals_no_update on public.call_signals for update to authenticated using(false) with check(false);
drop policy if exists call_signals_no_delete on public.call_signals;
create policy call_signals_no_delete on public.call_signals for delete to authenticated using(false);

-- Publish only the RLS-protected signaling table. Never use broadcast/public channels.
do $$
begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='call_signals') then
  alter publication supabase_realtime add table public.call_signals;
 end if;
exception when undefined_object then
 raise notice 'supabase_realtime publication not present; enable realtime publication before applying this migration';
end $$;
