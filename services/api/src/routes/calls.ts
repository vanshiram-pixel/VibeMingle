import type { FastifyInstance } from "fastify";
import { createClient } from "@supabase/supabase-js";
import { z } from "zod";
import { env } from "../config/env.js";
import { authenticatedSupabase } from "../plugins/supabase-user.js";
import { liveKitConfigured, mintLiveKitToken } from "../domain/video/livekit-provider.js";

const joinSchema=z.object({sessionId:z.string().uuid()}).strict();
const leaveSchema=z.object({reason:z.string().max(80).optional()}).strict();
const reportSchema=z.object({category:z.enum(["harassment","sexual_content","minor_safety","spam","hate","violence","impersonation","scam","other"]),description:z.string().max(2000).optional()}).strict();
function adminDb(){
 if(!env.supabaseUrl||!env.supabaseServiceRoleKey) throw new Error("Server database credentials are not configured");
 return createClient(env.supabaseUrl,env.supabaseServiceRoleKey,{auth:{persistSession:false,autoRefreshToken:false}});
}
export async function registerCallRoutes(app:FastifyInstance):Promise<void>{
 app.post("/v1/calls/token",async(request,reply)=>{
  const parsed=joinSchema.safeParse(request.body);
  if(!parsed.success)return reply.code(400).send({error:{code:"INVALID_SESSION",message:"Session id is invalid."}});
  const {user}=await authenticatedSupabase(request);
  if(!liveKitConfigured())return reply.code(503).send({error:{code:"CALL_PROVIDER_NOT_CONFIGURED",message:"LiveKit credentials are not configured."}});
  const db=adminDb();
  const {data,error}=await db.rpc("call_session_authorize",{p_session_id:parsed.data.sessionId,p_user_id:user.id});
  if(error){request.log.error({err:error},"call authorization RPC failed");return reply.code(503).send({error:{code:"CALL_AUTH_UNAVAILABLE",message:"Call authorization is temporarily unavailable."}});}
  const authorization=Array.isArray(data)?data[0]:data;
  if(!authorization?.authorized||!authorization.room_name)return reply.code(403).send({error:{code:"CALL_NOT_AUTHORIZED",message:"You are not allowed to join this call."}});
  const {data:activated,error:activationError}=await db.rpc("call_session_mark_active",{p_session_id:parsed.data.sessionId,p_user_id:user.id});
  if(activationError||activated!==true)return reply.code(409).send({error:{code:"CALL_SESSION_NOT_ACTIVE",message:"This call session cannot be joined."}});
  const token=await mintLiveKitToken({roomName:authorization.room_name,identity:user.id,ttlSeconds:120});
  return reply.send({url:env.livekitUrl,token:token.token,expiresAt:new Date(token.expiresAt).toISOString(),roomName:authorization.room_name});
 });

 app.post("/v1/calls/:sessionId/report",async(request,reply)=>{
  const params=z.object({sessionId:z.string().uuid()}).safeParse(request.params);const body=reportSchema.safeParse(request.body);
  if(!params.success||!body.success)return reply.code(400).send({error:{code:"INVALID_REPORT",message:"Report details are invalid."}});
  const {user}=await authenticatedSupabase(request);const db=adminDb();
  const {data:session,error:sessionError}=await db.from("match_sessions").select("participant_a,participant_b").eq("id",params.data.sessionId).maybeSingle();
  if(sessionError||!session)return reply.code(404).send({error:{code:"SESSION_NOT_FOUND",message:"Call session not found."}});
  const target=session.participant_a===user.id?session.participant_b:session.participant_b===user.id?session.participant_a:null;
  if(!target)return reply.code(403).send({error:{code:"CALL_NOT_AUTHORIZED",message:"You are not a participant in this call."}});
  const {error}=await db.from("user_reports").insert({reporter_id:user.id,reported_user_id:target,category:body.data.category,description:body.data.description??"",context_type:"call",context_id:params.data.sessionId});
  if(error){request.log.error({err:error},"call report insert failed");return reply.code(503).send({error:{code:"REPORT_UNAVAILABLE",message:"Report could not be submitted."}});}
  return reply.code(201).send({submitted:true});
 });
 app.post("/v1/calls/:sessionId/leave",async(request,reply)=>{
  const params=z.object({sessionId:z.string().uuid()}).safeParse(request.params);
  if(!params.success)return reply.code(400).send({error:{code:"INVALID_SESSION",message:"Session id is invalid."}});
  const body=leaveSchema.safeParse(request.body??{});
  if(!body.success)return reply.code(400).send({error:{code:"INVALID_LEAVE",message:"Leave reason is invalid."}});
  const {user}=await authenticatedSupabase(request);
  const db=adminDb();
  const {data,error}=await db.rpc("call_session_leave",{p_session_id:params.data.sessionId,p_user_id:user.id,p_reason:body.data.reason??"participant_left"});
  if(error){request.log.error({err:error},"call leave RPC failed");return reply.code(503).send({error:{code:"CALL_LIFECYCLE_UNAVAILABLE",message:"Call could not be ended right now."}});}
  if(data!==true)return reply.code(403).send({error:{code:"CALL_NOT_AUTHORIZED",message:"You are not allowed to end this call."}});
  return reply.code(204).send();
 });
}
