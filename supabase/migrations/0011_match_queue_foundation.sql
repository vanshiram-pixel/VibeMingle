-- V4.1 server-authoritative stranger matching queue primitives.
-- Queue rows contain preferences/consent metadata only; never SDP, media, or identity secrets.
create table if not exists public.match_queue (
 user_id uuid primary key references auth.users(id) on delete cascade,
 mode text not null default 'random' check(mode in ('random','manual','next')),
 age_band text,
 gender_preference text check(gender_preference is null or gender_preference in ('woman','man','nonbinary','any')),
 languages text[] not null default '{}',
 interests text[] not null default '{}',
 consent_at timestamptz not null,
 queued_at timestamptz not null default now(),
 heartbeat_at timestamptz not null default now(),
 queue_state text not null default 'waiting' check(queue_state in ('waiting','reserved'))
);
create index if not exists match_queue_waiting_order on public.match_queue(queued_at) where queue_state='waiting';
alter table public.match_queue enable row level security;
revoke all on public.match_queue from anon,authenticated;
-- queue operations are service/RPC-only; no direct client reads or writes.

create table if not exists public.match_pair_cooldowns (
 user_low uuid not null references auth.users(id) on delete cascade,
 user_high uuid not null references auth.users(id) on delete cascade,
 last_matched_at timestamptz not null default now(),
 primary key(user_low,user_high),
 constraint match_pair_order check(user_low<user_high)
);
alter table public.match_pair_cooldowns enable row level security;
revoke all on public.match_pair_cooldowns from anon,authenticated;

create or replace function public.match_queue_enter(
 p_mode text default 'random',p_age_band text default null,p_gender_preference text default 'any',
 p_languages text[] default '{}',p_interests text[] default '{}')
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid(); v_peer uuid; v_session uuid; v_now timestamptz:=clock_timestamp();
begin
 if v_uid is null then raise exception 'authentication_required'; end if;
 if not exists(select 1 from public.match_user_consent c where c.user_id=v_uid and c.enabled=true) then raise exception 'match_consent_required'; end if;
 if not exists(select 1 from public.match_eligibility e where e.user_id=v_uid and e.age_verified=true) then raise exception 'match_eligibility_required'; end if;
 if p_mode not in ('random','manual','next') then raise exception 'invalid_match_mode'; end if;
 if not exists(select 1 from public.profiles p where p.id=v_uid and p.discoverable=true) then raise exception 'profile_not_discoverable'; end if;
 if exists(select 1 from public.user_presence pr where pr.user_id=v_uid and pr.state='online' and pr.updated_at>v_now-interval '90 seconds') is false then raise exception 'presence_required'; end if;
 if exists(select 1 from public.call_sessions s where s.status in ('ringing','accepted','connecting','connected') and (s.caller_id=v_uid or s.callee_id=v_uid)) then raise exception 'participant_busy'; end if;
 -- Store/refresh own queue intent. Server applies filters without widening them.
 insert into public.match_queue(user_id,mode,age_band,gender_preference,languages,interests,consent_at,queued_at,heartbeat_at,queue_state)
 values(v_uid,p_mode,p_age_band,coalesce(p_gender_preference,'any'),coalesce(p_languages,'{}'),coalesce(p_interests,'{}'),v_now,v_now,v_now,'waiting')
 on conflict(user_id) do update set mode=excluded.mode,age_band=excluded.age_band,gender_preference=excluded.gender_preference,languages=excluded.languages,interests=excluded.interests,consent_at=excluded.consent_at,queued_at=excluded.queued_at,heartbeat_at=excluded.heartbeat_at,queue_state='waiting';
 -- Deliberately no peer pairing here: a dedicated transactional matcher worker
 -- must lock both rows, verify bilateral preferences/block/age/consent/cooldowns,
 -- reserve one session and emit authenticated events. This RPC only safely queues.
 return jsonb_build_object('state','queued','queued_at',v_now,'mode',p_mode);
end $$;
create or replace function public.match_queue_heartbeat()
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 update public.match_queue set heartbeat_at=clock_timestamp() where user_id=auth.uid() and queue_state='waiting';
 return found;
end $$;
create or replace function public.match_queue_leave()
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'authentication_required'; end if;
 delete from public.match_queue where user_id=auth.uid();
 return found;
end $$;
revoke all on function public.match_queue_enter(text,text,text,text[],text[]),public.match_queue_heartbeat(),public.match_queue_leave() from public,anon;
grant execute on function public.match_queue_enter(text,text,text,text[],text[]),public.match_queue_heartbeat(),public.match_queue_leave() to authenticated;
