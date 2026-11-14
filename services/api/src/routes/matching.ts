import type { FastifyInstance } from "fastify";
import { createClient } from "@supabase/supabase-js";
import { z } from "zod";
import { env } from "../config/env.js";
import { authenticatedSupabase } from "../plugins/supabase-user.js";

const preferences=z.object({
 region:z.string().max(12).optional(),
 language:z.string().max(12).optional(),
 interests:z.array(z.string().max(32)).max(10).optional(),
 genderFilter:z.enum(["any","women","men","other"]).optional()
}).strict();
function adminDb(){
 if(!env.supabaseUrl||!env.supabaseServiceRoleKey) throw new Error("Server database credentials are not configured");
 return createClient(env.supabaseUrl,env.supabaseServiceRoleKey,{auth:{persistSession:false,autoRefreshToken:false}});
}
export async function registerMatchingRoutes(app:FastifyInstance):Promise<void>{
 app.post("/v1/matching/queue",async(request,reply)=>{
  const parsed=preferences.safeParse(request.body??{});
  if(!parsed.success)return reply.code(400).send({error:{code:"MATCH_PREFS_INVALID",message:"Matching preferences are invalid."}});
  const {user}=await authenticatedSupabase(request);
  if(!env.supabaseServiceRoleKey)return reply.code(503).send({error:{code:"MATCHING_NOT_CONFIGURED",message:"Matching database is not configured."}});
  const db=adminDb();
  const {data,error}=await db.rpc("matching_enqueue_or_pair",{p_user:user.id,p_preferences:parsed.data});
  if(error){
   request.log.error({err:error},"matching admission RPC failed");
   const msg=error.message??"";
   if(msg.includes("consent_required"))return reply.code(403).send({error:{code:"MATCHING_CONSENT_REQUIRED",message:"Complete age assurance and required consents before matching."}});
   if(msg.includes("profile_missing"))return reply.code(409).send({error:{code:"MATCHING_PROFILE_REQUIRED",message:"Complete your profile before matching."}});
   return reply.code(503).send({error:{code:"MATCHING_UNAVAILABLE",message:"Matching is temporarily unavailable."}});
  }
  const result=Array.isArray(data)?data[0]:data;
  if(!result)return reply.code(503).send({error:{code:"MATCHING_EMPTY_RESPONSE",message:"Matching service returned no result."}});
  if(result.matched)return reply.send({status:"matched",sessionId:result.session_id,partnerId:result.partner_id});
  return reply.send({status:"queued"});
 });
 app.delete("/v1/matching/queue",async(request,reply)=>{
  const {user}=await authenticatedSupabase(request);
  if(!env.supabaseServiceRoleKey)return reply.code(503).send({error:{code:"MATCHING_NOT_CONFIGURED",message:"Matching database is not configured."}});
  const {error}=await adminDb().rpc("matching_queue_remove",{p_user:user.id});
  if(error){request.log.error({err:error},"matching queue cancellation failed");return reply.code(503).send({error:{code:"MATCHING_CANCEL_UNAVAILABLE",message:"Could not cancel matching right now."}});}
  return reply.code(204).send();
 });
}
