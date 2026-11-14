import {describe,it} from "node:test";
import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {resolve} from "node:path";

const migration=(name:string)=>readFileSync(resolve(process.cwd(),"../../supabase/migrations",name),"utf8");

describe("moderation SQL migration security contracts (static; no live DB)",()=>{
 it("rate limiter is atomic per bucket and fails closed at API call site",()=>{
  const sql=migration("0016_api_rate_limits.sql");
  assert.match(sql,/insert into api_rate_limits[\s\S]*on conflict\(bucket_key\) do update/i);
  assert.match(sql,/request_count\s*<=\s*p_limit/i);
  assert.match(sql,/revoke all on function public\.consume_api_rate_limit[\s\S]*from public, anon, authenticated/i);
  assert.match(sql,/grant execute on function public\.consume_api_rate_limit[\s\S]*to service_role/i);
  const route=readFileSync(resolve(process.cwd(),"src/routes/calls.ts"),"utf8");
  assert.match(route,/if\(error\)return null/i);
  assert.match(route,/consume_api_rate_limit/i);
 });
 it("report status mutation and audit insert share one SQL transaction/function",()=>{
  const sql=migration("0017_transactional_moderation_audit.sql");
  const fn=sql.slice(sql.indexOf("function public.moderation_update_report_with_audit"),sql.indexOf("create or replace function public.moderation_issue_sanction_with_audit"));
  assert.match(fn,/update public\.user_reports[\s\S]*returning \* into v_report/i);
  assert.match(fn,/if not found then raise exception/i);
  assert.match(fn,/insert into public\.moderation_audit_log/i);
  assert.match(fn,/return jsonb_build_object/i);
 });
 it("sanction SQL enforces role and duration constraints and writes audit",()=>{
  const sql=migration("0017_transactional_moderation_audit.sql");
  const fn=sql.slice(sql.indexOf("function public.moderation_issue_sanction_with_audit"),sql.indexOf("create or replace function public.moderation_revoke_sanction_with_audit"));
  assert.match(fn,/permanent ban requires superadmin/i);
  assert.match(fn,/temporary suspension requires admin/i);
  assert.match(fn,/p_duration_hours<1 or p_duration_hours>8760/i);
  assert.match(fn,/insert into public\.user_sanctions[\s\S]*insert into public\.moderation_audit_log/i);
 });
 it("revoke only deactivates active sanctions and audits in same function",()=>{
  const sql=migration("0017_transactional_moderation_audit.sql");
  const fn=sql.slice(sql.indexOf("function public.moderation_revoke_sanction_with_audit"));
  assert.match(fn,/where id=p_sanction_id and active=true returning \* into v_row/i);
  assert.match(fn,/if not found then raise exception/i);
  assert.match(fn,/insert into public\.moderation_audit_log/i);
 });
 it("all atomic RPCs are service-role only",()=>{
  const sql=migration("0017_transactional_moderation_audit.sql");
  for(const name of ["moderation_update_report_with_audit","moderation_issue_sanction_with_audit","moderation_revoke_sanction_with_audit"]){
   assert.match(sql,new RegExp("revoke all on function public\\."+name+"[\\s\\S]*from public,anon,authenticated","i"));
   assert.match(sql,new RegExp("grant execute on function public\\."+name+"[\\s\\S]*to service_role","i"));
  }
 });
});
