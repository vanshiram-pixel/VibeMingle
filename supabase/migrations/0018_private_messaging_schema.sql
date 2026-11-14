-- VibeMingle 0018: private friend messaging foundation.
-- Direct client inserts are intentionally disabled; APIs/RPCs enforce friendship and blocks.
create table if not exists public.conversations(
 id uuid primary key default gen_random_uuid(),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 user_a uuid not null references auth.users(id) on delete cascade,
 user_b uuid not null references auth.users(id) on delete cascade,
 check(user_a<user_b),
 unique(user_a,user_b)
);
create table if not exists public.conversation_members(
 conversation_id uuid not null references public.conversations(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 joined_at timestamptz not null default now(),
 last_read_at timestamptz,
 primary key(conversation_id,user_id)
);
create table if not exists public.messages(
 id uuid primary key default gen_random_uuid(),
 conversation_id uuid not null references public.conversations(id) on delete cascade,
 sender_id uuid not null references auth.users(id) on delete cascade,
 body text not null check(char_length(btrim(body)) between 1 and 4000),
 created_at timestamptz not null default now(),
 edited_at timestamptz,
 deleted_at timestamptz
);
create index if not exists messages_conversation_cursor on public.messages(conversation_id,created_at desc,id desc);
create index if not exists conversations_member_updated on public.conversations(updated_at desc);
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
drop policy if exists conversations_member_read on public.conversations;
create policy conversations_member_read on public.conversations for select to authenticated
 using(exists(select 1 from public.conversation_members m where m.conversation_id=id and m.user_id=auth.uid()));
drop policy if exists conversation_members_self_read on public.conversation_members;
create policy conversation_members_self_read on public.conversation_members for select to authenticated using(user_id=auth.uid());
drop policy if exists messages_member_read on public.messages;
create policy messages_member_read on public.messages for select to authenticated
 using(exists(select 1 from public.conversation_members m where m.conversation_id=messages.conversation_id and m.user_id=auth.uid()));
-- No authenticated INSERT/UPDATE/DELETE policies on these tables.
-- A service/API layer must validate friend status, blocks, sanctions, and rate limits.
