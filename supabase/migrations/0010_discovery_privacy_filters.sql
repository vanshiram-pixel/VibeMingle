-- V4.1 discovery/privacy controls: explicit opt-in visibility and safe profile discovery.
alter table public.profiles
 add column if not exists discoverable boolean not null default true,
 add column if not exists age_band text,
 add column if not exists languages text[] not null default '{}',
 add column if not exists interests text[] not null default '{}',
 add column if not exists gender text,
 add column if not exists updated_profile_at timestamptz not null default now();
alter table public.profiles drop constraint if exists profiles_age_band_check;
alter table public.profiles add constraint profiles_age_band_check
 check(age_band is null or age_band in ('18_24','25_34','35_44','45_plus'));
alter table public.profiles drop constraint if exists profiles_gender_check;
alter table public.profiles add constraint profiles_gender_check
 check(gender is null or gender in ('woman','man','nonbinary','prefer_not_to_say'));
create index if not exists profiles_discoverable_idx on public.profiles(discoverable,id) where discoverable=true;

-- Discovery is server-filtered: never returns blocked, self, or undiscoverable profiles.
create or replace function public.discover_profiles(
 p_query text default null,p_age_band text default null,p_gender text default null,
 p_language text default null,p_interest text default null,p_limit integer default 20)
returns table(id uuid,username text,display_name text,avatar_url text,bio text,age_band text,gender text,languages text[],interests text[])
language plpgsql stable security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid(); v_limit integer;
begin
 if v_uid is null then raise exception 'authentication_required'; end if;
 v_limit:=least(greatest(coalesce(p_limit,20),1),40);
 return query select p.id,p.username,p.display_name,p.avatar_url,p.bio,p.age_band,p.gender,p.languages,p.interests
 from public.profiles p
 where p.discoverable=true and p.id<>v_uid
 and (p_query is null or length(trim(p_query))<2 or p.username ilike '%'||trim(p_query)||'%' or p.display_name ilike '%'||trim(p_query)||'%')
 and (p_age_band is null or p.age_band=p_age_band)
 and (p_gender is null or p.gender=p_gender)
 and (p_language is null or p_language=any(p.languages))
 and (p_interest is null or p_interest=any(p.interests))
 and not exists(select 1 from public.user_blocks b where
  (b.blocker_id=v_uid and b.blocked_id=p.id) or (b.blocker_id=p.id and b.blocked_id=v_uid))
 order by p.updated_at desc limit v_limit;
end $$;
revoke all on function public.discover_profiles(text,text,text,text,text,integer) from public,anon;
grant execute on function public.discover_profiles(text,text,text,text,text,integer) to authenticated;
