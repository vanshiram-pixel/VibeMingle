import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { createClient } from "@supabase/supabase-js";
import { authenticatedSupabase } from "../plugins/supabase-user.js";
import { env } from "../config/env.js";
const schema=z.object({granted:z.boolean(),policyVersion:z.string().min(1).max(80}).strict();
export async function registerAiConsentRoutes(app:FastifyInstance){
 app.get("/v1/ai/consent",async(request,reply)=>{
  const {user,client}=await authenticatedSupabase(request);
  const {data,error}=await client.from("user_consents").select("granted,policy_version,recorded_at,withdrawn_at").eq("user_id",user.id).eq("purpose","ai_translation").order("recorded_at",{ascending:false}).limit(1).maybeSingle();
  if(error)return reply.code(503).send({error:{code:"CONSENT_UNAVAILABLE",message:"Consent status unavailable."}});
  return reply.send({data:data??{granted:false,policy_version:null,recorded_at:null,withdrawn_at:null}});
 });
 app.put("/v1/ai/consent",async(request,reply)=>{
  const parsed=schema.safeParse(request.body);if(!parsed.success)return reply.code(400).send({error:{code:"INVALID_CONSENT",message:"Consent request is invalid."}});
  const {user}=await authenticatedSupabase(request);
  if(!env.supabaseUrl||!env.supabaseServiceRoleKey)return reply.code(503).send({error:{code:"CONSENT_WRITE_UNAVAILABLE",message:"Consent updates are unavailable."}});
  const admin=createClient(env.supabaseUrl,env.supabaseServiceRoleKey,{auth:{persistSession:false}});
  const {data,error}=await admin.from("user_consents").insert({user_id:user.id,purpose:"ai_translation",policy_version:parsed.data.policyVersion,granted:parsed.data.granted,withdrawn_at:parsed.data.granted?null:new Date().toISOString(),metadata:{source:"api"}}).select("granted,policy_version,recorded_at,withdrawn_at").single();
  if(error)return reply.code(503).send({error:{code:"CONSENT_WRITE_FAILED",message:"Consent could not be recorded."}});
  return reply.code(201).send({data});
 });
}