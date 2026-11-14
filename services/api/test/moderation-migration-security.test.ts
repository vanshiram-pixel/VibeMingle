import {describe,it} from "node:test";
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";

const migration=(name)=>readFile(new URL(`../../../supabase/migrations/${name}`,import.meta.url),"utf8");

describe("moderation database security contracts (static migration checks)",()=>{
 it("keeps admin/sanction/audit tables behind RLS and denies client roles",async()=>{
  const sql=await migration("0015_moderation_admin_and_sanctions.sql");
  for(const table of ["admin_roles","user_sanctions","moderation_audit_log"]){
   assert.match(sql,new RegExp(`alter table public\.${table} enable row level security`,"i"));
  }
  assert.match(sql,/revoke all on public\.admin_roles, public\.user_sanctions, public\.moderation_audit_log from anon, authenticated/i);
 });
 it("exposes rate-limit RPC only to service role and uses atomic upsert",async()=>{
  const sql=await migration("0016_api_rate_limits.sql");
  assert.match(sql,/on conflict\(bucket_key\) do update/i);
  assert.match(sql,/revoke all on function public\.consume_api_rate_limit\(text,integer,integer\) from public, anon, authenticated/i);
  assert.match(sql,/grant execute on function public\.consume_api_rate_limit\(text,integer,integer\) to service_role/i);
 });
 it("keeps moderation changes and audit inserts in same RPC functions",async()=>{
  const sql=await migration("0017_transactional_moderation_audit.sql");
  for(const fn of ["moderation_update_report_with_audit","moderation_issue_sanction_with_audit","moderation_revoke_sanction_with_audit"]){
   const start=sql.indexOf(`function public.${fn}`);
   assert.notEqual(start,-1,`missing ${fn}`);
   const end=sql.indexOf("$$;",start);
   const body=sql.slice(start,end);
   assert.match(body,/insert into public\.moderation_audit_log/i,`${fn} must write audit`);
  }
  assert.match(sql,/revoke all on function public\.moderation_update_report_with_audit/i);
  assert.match(sql,/grant execute on function public\.moderation_update_report_with_audit[^;]*to service_role/i);
 });
});
