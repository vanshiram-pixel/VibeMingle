-- VibeMingle profile foundation. Apply only through reviewed Supabase migrations.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null default '',
  bio text not null default '',
  avatar_url text,
  visibility text not null default 'public'
    check (visibility in ('public', 'friends', 'private')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (
    username = lower(username)
    and username ~ '^[a-z0-9_]{3,24}$'
  ),
  constraint profiles_display_name_length check (char_length(display_name) <= 60),
  constraint profiles_bio_length check (char_length(bio) <= 240)
);

create index if not exists profiles_visibility_updated_idx
  on public.profiles (visibility, updated_at desc);

alter table public.profiles enable row level security;

-- Authenticated users may read public profiles; owners can always read their own.
drop policy if exists "profiles_read_public_or_self" on public.profiles;
create policy "profiles_read_public_or_self"
  on public.profiles for select to authenticated
  using (visibility = 'public' or id = (select auth.uid()));

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
  on public.profiles for insert to authenticated
  with check (id = (select auth.uid()));

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create or replace function public.profiles_touch_updated_at()
returns trigger language plpgsql set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles
for each row execute function public.profiles_touch_updated_at();

-- Create a private-by-default profile when a new auth account is provisioned.
create or replace function public.profiles_create_for_auth_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  base_name text;
  candidate text;
begin
  base_name := lower(regexp_replace(coalesce(new.raw_user_meta_data ->> 'preferred_username',
    new.raw_user_meta_data ->> 'name', 'user'), '[^a-zA-Z0-9_]', '', 'g'));
  base_name := left(base_name, 15);
  if length(base_name) < 3 then
    base_name := 'user';
  end if;
  candidate := base_name || '_' || left(replace(new.id::text, '-', ''), 6);

  insert into public.profiles (id, username, display_name, avatar_url, visibility)
  values (
    new.id,
    candidate,
    left(coalesce(new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name', ''), 60),
    new.raw_user_meta_data ->> 'avatar_url',
    'private'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile after insert on auth.users
for each row execute function public.profiles_create_for_auth_user();

revoke all on function public.profiles_touch_updated_at() from public, anon, authenticated;
revoke all on function public.profiles_create_for_auth_user() from public, anon, authenticated;
