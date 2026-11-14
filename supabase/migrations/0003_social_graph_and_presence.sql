-- VibeMingle 0003: social graph and privacy-aware presence.
create table if not exists public.friend_requests(
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references auth.users(id) on delete cascade,
 receiver_id uuid not null references auth.users(id) on delete cascade,
 status text not null default 'pending' check(status in ('pending','accepted','rejected','cancelled')),
 created_at timestamptz not null default now(), responded_at timestamptz,
 check(sender_id<>receiver_id)
);
create unique index if not exists friend_requests_pending_pair on public.friend_requests(sender_id,receiver_id) where status='pending';
create index if not exists friend_requests_receiver on public.friend_requests(receiver_id,status,created_at desc);
create table if not exists public.friendships(
 user_a uuid not null references auth.users(id) on delete cascade,
 user_b uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(user_a,user_b), check(user_a<user_b)
);
create table if not exists public.presence_settings(
 user_id uuid primary key references auth.users(id) on delete cascade,
 visibility text not null default 'friends' check(visibility in ('everyone','friends','nobody')),
 show_online boolean not null default true,
 updated_at timestamptz not null default now()
);
alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
alter table public.presence_settings enable row level security;
drop policy if exists friend_requests_participant_read on public.friend_requests;
create policy friend_requests_participant_read on public.friend_requests for select to authenticated using(auth.uid()=sender_id or auth.uid()=receiver_id);
drop policy if exists presence_settings_self_read on public.presence_settings;
create policy presence_settings_self_read on public.presence_settings for select to authenticated using(auth.uid()=user_id);
-- Client writes intentionally absent: trusted APIs must validate mutual blocks,
-- sanctions, request direction, rate limits and idempotent accept/reject.
-- Friendship reads are server-projected after block/visibility checks; no direct RLS select.
