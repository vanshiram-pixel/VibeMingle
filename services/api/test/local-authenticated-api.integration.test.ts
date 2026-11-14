/**
 * Opt-in authenticated API integration tests against a LOCAL Supabase instance only.
 * Never point SUPABASE_URL at hosted/production for this test.
 * Run after local Supabase migrations: SUPABASE_LOCAL_INTEGRATION=1 npm test --workspace services/api
 */
import { describe, it } from "node:test";
import assert from "node:assert/strict";
import Fastify from "fastify";
import { createClient } from "@supabase/supabase-js";
import { registerMeRoutes } from "../src/routes/me.js";
import { registerOnboardingRoutes } from "../src/routes/onboarding.js";
import { registerAuthRoutes } from "../src/routes/auth.js";
import { registerMatchingRoutes } from "../src/routes/matching.js";
import { registerSocialRoutes } from "../src/routes/social.js";
import { registerCallRoutes } from "../src/routes/calls.js";

const enabled=process.env.SUPABASE_LOCAL_INTEGRATION==="1";
const url=process.env.SUPABASE_URL??"";
const anon=process.env.SUPABASE_ANON_KEY??"";
const service=process.env.SUPABASE_SERVICE_ROLE_KEY??"";
const localHost=["localhost","127.0.0.1","supabase","kong"].some(host=>{try{return new URL(url).hostname===host}catch{return false}});
const suite=enabled&&localHost&&anon&&service?describe:describe.skip;

suite("local Supabase authenticated API ownership",()=>{
 it("isolates /v1/me and profile PATCH to each verified Auth identity",async()=>{
  assert.ok(localHost,"integration URL must be local; hosted Supabase is forbidden");
  const admin=createClient(url,service,{auth:{persistSession:false,autoRefreshToken:false}});
  const app=Fastify({logger:false});
  app.setErrorHandler((error,request,reply)=>reply.code(error instanceof Error&&"statusCode" in error?Number((error as {statusCode:number}).statusCode):500).send({error:{message:"request failed"}}));
  await app.register(registerAuthRoutes); await app.register(registerMeRoutes);
  await app.register(registerOnboardingRoutes); await app.register(registerMatchingRoutes);
  await app.register(registerSocialRoutes); await app.register(registerCallRoutes);
  const suffix=`${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const emails=[`api-a-${suffix}@example.test`,`api-b-${suffix}@example.test`];
  const password="LocalOnly-Integration-Password-42!";
  const ids:string[]=[]; const tokens:string[]=[];
  try {
   for(const email of emails){
    const created=await admin.auth.admin.createUser({email,password,email_confirm:true});
    assert.ifError(created.error); assert.ok(created.data.user); ids.push(created.data.user.id);
    const auth=createClient(url,anon,{auth:{persistSession:false,autoRefreshToken:false}});
    const signed=await auth.auth.signInWithPassword({email,password});
    assert.ifError(signed.error); assert.ok(signed.data.session?.access_token);
    tokens.push(signed.data.session.access_token);
   }
   const a=await app.inject({method:"PATCH",url:"/v1/me/profile",headers:{authorization:`Bearer ${tokens[0]}`},payload:{display_name:"Local User A"}});
   assert.equal(a.statusCode,200,a.body); assert.equal(a.json().data.id,ids[0]);
   const b=await app.inject({method:"PATCH",url:"/v1/me/profile",headers:{authorization:`Bearer ${tokens[1]}`},payload:{display_name:"Local User B"}});
   assert.equal(b.statusCode,200,b.body); assert.equal(b.json().data.id,ids[1]);
   const aRead=await app.inject({method:"GET",url:"/v1/me",headers:{authorization:`Bearer ${tokens[0]}`}});
   const bRead=await app.inject({method:"GET",url:"/v1/me",headers:{authorization:`Bearer ${tokens[1]}`}});
   assert.equal(aRead.json().data.id,ids[0]); assert.equal(aRead.json().data.display_name,"Local User A");
   assert.equal(bRead.json().data.id,ids[1]); assert.equal(bRead.json().data.display_name,"Local User B");
   const forged=await app.inject({method:"PATCH",url:"/v1/me/profile",headers:{authorization:
    `Bearer ${tokens[0]}`},payload:{id:ids[1],display_name:"Forged B"}});
   assert.equal(forged.statusCode,400,"strict profile schema must reject client-supplied identity");
   const bAfter=await app.inject({method:"GET",url:"/v1/me",headers:{authorization:
    `Bearer ${tokens[1]}`}});
   assert.equal(bAfter.json().data.display_name,"Local User B","A must not overwrite B");
  } finally {
   await app.close();
   for(const id of ids) await admin.auth.admin.deleteUser(id);
  }
 });
});
