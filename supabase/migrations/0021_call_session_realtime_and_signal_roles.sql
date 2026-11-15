-- Tighten signaling roles and make call-session changes visible to participants.
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
    and (
      (kind='offer' and sender_id=c.caller_id)
      or (kind='answer' and sender_id=c.callee_id)
      or kind in('ice','renegotiate','hangup')
    )
 )
);

do $$
begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='call_sessions') then
  execute 'alter publication supabase_realtime add table public.call_sessions';
 end if;
exception when undefined_object then
 raise notice 'supabase_realtime publication not present; enable realtime publication before applying migration';
end $$;
