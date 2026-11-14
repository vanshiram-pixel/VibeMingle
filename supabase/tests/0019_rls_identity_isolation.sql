-- VibeMingle RLS integration test: identity isolation, using local Supabase only.
-- This test uses pgTAP and authenticated role JWT claims; never run on hosted prod.
begin;
select plan(13);

-- Seed two isolated auth identities in disposable local auth schema.
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

-- A: own profile visible; B profile hidden under self-only policy.
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
select is((select count(*)::int from public.profiles where id='10000000-0000-4000-8000-000000000001'),1,'A sees own profile');
select is((select count(*)::int from public.profiles where id='20000000-0000-4000-8000-000000000002'),0,'A cannot read B profile');
select is((select count(*)::int from public.user_consents where user_id='10000000-0000-4000-8000-000000000001'),1,'A sees own consent');
select is((select count(*)::int from public.user_consents where user_id='20000000-0000-4000-8000-000000000002'),0,'A cannot read B consent');
select is((select count(*)::int from public.user_blocks where blocker_id='10000000-0000-4000-8000-000000000001'),1,'A sees own block');
select is((select count(*)::int from public.user_blocks where blocker_id='20000000-0000-4000-8000-000000000002'),0,'A cannot read B block edge');
select is((select count(*)::int from public.user_reports where reporter_id='10000000-0000-4000-8000-000000000001'),1,'A sees own report receipt');
select is((select count(*)::int from public.user_reports where reporter_id='20000000-0000-4000-8000-000000000002'),0,'A cannot read B report receipt');

-- A cannot forge a profile belonging to B (expect RLS violation).
select throws_ok($$insert into public.profiles(id,display_name) values('20000000-0000-4000-8000-000000000002','forged')$$,'42501',null,'A cannot insert B profile');

-- B can see own profile, but not A's report receipt.
select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000002',true);
select set_config('request.jwt.claims','{"sub":"20000000-0000-4000-8000-000000000002","role":"authenticated"}',true);
select is((select count(*)::int from public.profiles where id='20000000-0000-4000-8000-000000000002'),1,'B sees own profile');
select is((select count(*)::int from public.user_reports where reporter_id='10000000-0000-4000-8000-000000000001'),0,'B cannot read A report receipt');

-- Client cannot create/alter report records directly (no INSERT grant).
select throws_ok($$insert into public.user_reports(reporter_id,reported_user_id,category) values('20000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001','spam')$$,'42501',null,'authenticated cannot insert report directly');

select * from finish();
rollback;
