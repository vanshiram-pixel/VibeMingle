-- VibeMingle 0026: chat reactions with member-scoped visibility and self-only writes.
create table if not exists public.message_reactions(
 message_id uuid not null references public.messages(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 emoji text not null check(emoji in ('👍','❤️','😂','😮','😢','🙏','🔥','🎉')),
 created_at timestamptz not null default now(),
 primary key(message_id,user_id,emoji)
);
create index if not exists message_reactions_message on public.message_reactions(message_id);
alter table public.message_reactions enable row level security;
drop policy if exists message_reactions_member_read on public.message_reactions;
create policy message_reactions_member_read on public.message_reactions for select to authenticated
 using(exists(select 1 from public.messages m join public.conversation_members cm on cm.conversation_id=m.conversation_id where m.id=message_id and cm.user_id=auth.uid()));
drop policy if exists message_reactions_self_insert on public.message_reactions;
create policy message_reactions_self_insert on public.message_reactions for insert to authenticated
 with check(user_id=auth.uid() and exists(select 1 from public.messages m join public.conversation_members cm on cm.conversation_id=m.conversation_id where m.id=message_id and cm.user_id=auth.uid() and m.deleted_at is null));
drop policy if exists message_reactions_self_delete on public.message_reactions;
create policy message_reactions_self_delete on public.message_reactions for delete to authenticated using(user_id=auth.uid());
grant select,insert,delete on public.message_reactions to authenticated;
