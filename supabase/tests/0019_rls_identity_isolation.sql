-- VibeMingle RLS integration test: two-user isolation on disposable LOCAL Supabase only.
begin;
insert into auth.users(id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at,raw_app_meta_data,raw_user_meta_data,is_sso_user)
values
 ('10000000-0000-4000-8000-000000000001','authenticated','authenticated','rls-a@example.test','',now(),now(),now(),'{}','{}',false),
 ('20000000-0000-4000-8000-000000000002','authenticated','authenticated','rls-b@example.test','',now(),now(),now(),'{}','{}',false)
on conflict(id) do nothing;
insert into public.profiles(id,display_name) values
 ('10000000-0000-4000-8000-000000000001','RLS Test A'),
 ('20000000-0000-4000-8000-000000000002','RLS Test B')
on conflict(id) do update set display_name=excluded.display_name;
insert into public.user_consents(user_id,purpose,policy_version,granted) values
 ('10000000-0000-4000-8000-000000000001','terms','test-v1',true),
 ('20000000-0000-4000-8000-000000000002','terms','test-v1',true);
insert into public.user_blocks(blocker_id,blocked_id) values
 ('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000002');
insert into public.user_reports(reporter_id,reported_user_id,category,description)
values('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000002','spam','test receipt');

set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
do $$
begin
 if (select count(*) from public.profiles where id='10000000-0000-4000-8000-000000000001')<>1 then raise exception 'FAIL A own profile'; end if;
 if (select count(*) from public.profiles where id='20000000-0000-4000-8000-000000000002')<>0 then raise exception 'FAIL A reads B profile'; end if;
 if (select count(*) from public.user_consents where user_id='10000000-0000-4000-8000-000000000001')<>1 then raise exception 'FAIL A own consent'; end if;
 if (select count(*) from public.user_consents where user_id='20000000-0000-4000-8000-000000000002')<>0 then raise exception 'FAIL A reads B consent'; end if;
 if (select count(*) from public.user_blocks where blocker_id='10000000-0000-4000-8000-000000000001')<>1 then raise exception 'FAIL A own block'; end if;
 if (select count(*) from public.user_blocks where blocker_id='20000000-0000-4000-8000-000000000002')<>0 then raise exception 'FAIL A reads B block'; end if;
 if (select count(*) from public.user_reports where reporter_id='10000000-0000-4000-8000-000000000001')<>1 then raise exception 'FAIL A own report'; end if;
 if (select count(*) from public.user_reports where reporter_id='20000000-0000-4000-8000-000000000002')<>0 then raise exception 'FAIL A reads B report'; end if;
 update public.profiles set display_name='forged cross-user update' where id='20000000-0000-4000-8000-000000000002';
 if found then raise exception 'FAIL A updated B profile'; end if;
 begin insert into public.profiles(id,display_name) values('20000000-0000-4000-8000-000000000002','forged'); raise exception 'FAIL A inserted B profile'; exception when insufficient_privilege then null; end;
end $$;

select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000002',true);
select set_config('request.jwt.claims','{"sub":"20000000-0000-4000-8000-000000000002","role":"authenticated"}',true);
do $$
begin
 if (select count(*) from public.profiles where id='20000000-0000-4000-8000-000000000002')<>1 then raise exception 'FAIL B own profile'; end if;
 if (select count(*) from public.user_reports where reporter_id='10000000-0000-4000-8000-000000000001')<>0 then raise exception 'FAIL B reads A report'; end if;
 update public.profiles set display_name='forged cross-user update' where id='10000000-0000-4000-8000-000000000001';
 if found then raise exception 'FAIL B updated A profile'; end if;
 begin insert into public.user_reports(reporter_id,reported_user_id,category) values('20000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001','spam'); raise exception 'FAIL client inserted report'; exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback;
select 'RLS identity isolation assertions: PASS (14 checks)' as result;
