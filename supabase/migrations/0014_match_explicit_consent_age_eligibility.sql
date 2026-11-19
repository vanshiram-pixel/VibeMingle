-- V4.1 explicit opt-in and server-issued age eligibility. DOB/identity proof is never public.
create table if not exists public.match_eligibility (
 user_id uuid primary key references auth.users(id) on delete cascade,
 age_verified boolean not null default false,
 verified_at timestamptz,
 verification_method text,
 verification_reference_hash text,
 updated_at timestamptz not null default now(),
 constraint match_eligibility_consistency check ((age_verified and verified_at is not null and verification_method is not null) or (not age_verified and verified_at is null))
);
alter table public.match_eligibility enable row level security;
revoke all on public.match_eligibility from anon,authenticated;

create table if not exists public.match_user_consent (
 user_id uuid primary key references auth.users(id) on delete cascade,
 enabled boolean not null default false,
 consent_version text not null,
 consented_at timestamptz,
 updated_at timestamptz not null default now(),
 constraint match_consent_consistency check ((enabled and consented_at is not null) or (not enabled and consented_at is null))
);
alter table public.match_user_consent enable row level security;
revoke all on public.match_user_consent from anon,authenticated;

create or replace function public.match_consent_set(p_enabled boolean,p_version text)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid(); v_now timestamptz:=clock_timestamp();
begin
 if v_uid is null then raise exception 'authentication_required'; end if;
 if p_version is null or length(trim(p_version))<1 or length(p_version)>40 then raise exception 'invalid_consent_version'; end if;
 insert into public.match_user_consent(user_id,enabled,consent_version,consented_at,updated_at)
 values(v_uid,p_enabled,p_version,case when p_enabled then v_now else null end,v_now)
 on conflict(user_id) do update set enabled=excluded.enabled,consent_version=excluded.consent_version,consented_at=excluded.consented_at,updated_at=excluded.updated_at;
 if not p_enabled then delete from public.match_queue where user_id=v_uid; end if;
 return jsonb_build_object('enabled',p_enabled,'version',p_version,'updated_at',v_now);
end $$;
revoke all on function public.match_consent_set(boolean,text) from public,anon;
grant execute on function public.match_consent_set(boolean,text) to authenticated;

-- Only trusted verification backend/service role may set age verification.
create or replace function public.match_eligibility_set_verified(p_user_id uuid,p_verified boolean,p_method text,p_reference_hash text)
returns void language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if coalesce(auth.role(),'')<>'service_role' then raise exception 'service_role_required'; end if;
 if p_user_id is null then raise exception 'user_required'; end if;
 if p_verified and (p_method is null or length(trim(p_method))<3 or p_reference_hash is null or length(p_reference_hash)<32) then raise exception 'verification_evidence_required'; end if;
 insert into public.match_eligibility(user_id,age_verified,verified_at,verification_method,verification_reference_hash,updated_at)
 values(p_user_id,p_verified,case when p_verified then clock_timestamp() else null end,case when p_verified then p_method else null end,case when p_verified then p_reference_hash else null end,clock_timestamp())
 on conflict(user_id) do update set age_verified=excluded.age_verified,verified_at=excluded.verified_at,verification_method=excluded.verification_method,verification_reference_hash=excluded.verification_reference_hash,updated_at=excluded.updated_at;
 if not p_verified then delete from public.match_queue where user_id=p_user_id; end if;
end $$;
revoke all on function public.match_eligibility_set_verified(uuid,boolean,text,text) from public,anon,authenticated;
grant execute on function public.match_eligibility_set_verified(uuid,boolean,text,text) to service_role;

-- Rebuild queue entry: consent timestamp is sourced from explicit user action, never fabricated.
create or replace function public.match_queue_enter(
 p_mode text default 'random',p_age_band text default null,p_gender_preference text default 'any',
 p_languages text[] default '{}',p_interests text[] default '{}')
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare v_uid uuid:=auth.uid(); v_now timestamptz:=clock_timestamp(); v_consent public.match_user_consent;
begin
 if v_uid is null then raise exception 'authentication_required'; end if;
 if p_mode not in ('random','manual','next') then raise exception 'invalid_match_mode'; end if;
 select * into v_consent from public.match_user_consent where user_id=v_uid and enabled=true and consented_at is not null;
 if not found then raise exception 'match_consent_required'; end if;
 if not exists(select 1 from public.match_eligibility e where e.user_id=v_uid and e.age_verified=true and e.verified_at is not null) then raise exception 'age_verification_required'; end if;
 if not exists(select 1 from public.profiles p where p.id=v_uid and p.discoverable=true) then raise exception 'profile_not_discoverable'; end if;
 if not exists(select 1 from public.user_presence pr where pr.user_id=v_uid and pr.state='online' and pr.updated_at>v_now-interval '90 seconds') then raise exception 'presence_required'; end if;
 if exists(select 1 from public.call_sessions s where s.status in ('ringing','accepted','connecting','connected') and (s.caller_id=v_uid or s.callee_id=v_uid))
 or exists(select 1 from public.match_sessions m where m.state in('reserved','connecting','active') and (m.user_a=v_uid or m.user_b=v_uid)) then raise exception 'participant_busy'; end if;
 insert into public.match_queue(user_id,mode,age_band,gender_preference,languages,interests,consent_at,queued_at,heartbeat_at,queue_state)
 values(v_uid,p_mode,p_age_band,coalesce(p_gender_preference,'any'),coalesce(p_languages,'{}'),coalesce(p_interests,'{}'),v_consent.consented_at,v_now,v_now,'waiting')
 on conflict(user_id) do update set mode=excluded.mode,age_band=excluded.age_band,gender_preference=excluded.gender_preference,languages=excluded.languages,interests=excluded.interests,consent_at=excluded.consent_at,queued_at=excluded.queued_at,heartbeat_at=excluded.heartbeat_at,queue_state='waiting';
 return jsonb_build_object('state','queued','queued_at',v_now,'mode',p_mode);
end $$;
revoke all on function public.match_queue_enter(text,text,text,text[],text[]) from public,anon;
grant execute on function public.match_queue_enter(text,text,text,text[],text[]) to authenticated;
