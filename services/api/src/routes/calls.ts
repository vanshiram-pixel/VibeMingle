import type { FastifyInstance } from "fastify";
import { createClient } from "@supabase/supabase-js";
import { z } from "zod";
import { env } from "../config/env.js";
import { authenticatedSupabase } from "../plugins/supabase-user.js";
import { liveKitConfigured, mintLiveKitToken } from "../domain/video/livekit-provider.js";

const joinSchema=z.object({sessionId:z.string().uuid()}).strict();
const leaveSchema=z.object({reason:z.string().max(80).optional()}).strict();
const reportSchema=z.object({category:z.enum(["harassment","sexual_content","minor_safety","spam","hate","violence","impersonation","scam","other"]),description:z.string().max(2000).optional()}).strict();
const moderationStatusSchema=z.object({status:z.enum(["triaged","investigating","actioned","dismissed"])}).strict();
const sanctionSchema=z.object({userId:z.string().uuid(),type:z.enum(["warning","temporary_suspension","permanent_ban"]),reason:z.string().min(3).max(2000),durationHours:z.number().int().min(1).max(8760).optional()}).strict();
async function requireModerator(db:any,userId:string):Promise<boolean>{
 const {data,error}=await db.from("admin_roles").select("role").eq("user_id",userId).eq("enabled",true).maybeSingle();
 return !error&&!!data&&["moderator","admin","superadmin"].includes(data.role);
}
async function enforceCallSanction(db:any,userId:string,reply:any):Promise<boolean>{
 const {data,error}=await db.from("user_sanctions").select("sanction_type,expires_at").eq("user_id",userId).eq("active",true).in("sanction_type",["temporary_suspension","permanent_ban"]);
 if(error){reply.code(503).send({error:{code:"SANCTION_CHECK_UNAVAILABLE",message:"Account eligibility could not be verified."}});return false;}
 const now=Date.now();const blocked=(data??[]).some((s:any)=>s.sanction_type==="permanent_ban"||!s.expires_at||new Date(s.expires_at).getTime()>now);
 if(blocked)reply.code(403).send({error:{code:"ACCOUNT_SUSPENDED",message:"This account is restricted from calls."}});return !blocked;
}
function adminDb(){
 if(!env.supabaseUrl||!env.supabaseServiceRoleKey) throw new Error("Server database credentials are not configured");
 return createClient(env.supabaseUrl,env.supabaseServiceRoleKey,{auth:{persistSession:false,autoRefreshToken:false}});
}
export async function registerCallRoutes(app:FastifyInstance):Promise<void>{
 app.get("/v1/admin/moderation/reports",async(request,reply)=>{
  const {user}=await authenticatedSupabase(request);const db=adminDb();
  if(!await requireModerator(db,user.id))return reply.code(403).send({error:{code:"MODERATION_FORBIDDEN",message:"Moderator access required."}});
  const query=z.object({status:z.enum(["submitted","triaged","investigating","actioned","dismissed"]).optional(),limit:z.coerce.number().int().min(1).max(100).optional()}).safeParse(request.query);
  if(!query.success)return reply.code(400).send({error:{code:"INVALID_QUERY",message:"Report filters are invalid."}});
  let q=db.from("user_reports").select("id,reporter_id,reported_user_id,category,description,context_type,context_id,status,created_at").order("created_at",{ascending:true}).limit(query.data.limit??50);
  if(query.data.status)q=q.eq("status",query.data.status);
  const {data,error}=await q;if(error)return reply.code(503).send({error:{code:"MODERATION_READ_FAILED",message:"Report queue unavailable."}});
  return reply.send({data});
 });
 app.patch("/v1/admin/moderation/reports/:reportId",async(request,reply)=>{
  const params=z.object({reportId:z.string().uuid()}).safeParse(request.params);const body=moderationStatusSchema.safeParse(request.body);
  if(!params.success||!body.success)return reply.code(400).send({error:{code:"INVALID_MODERATION_ACTION",message:"Report action is invalid."}});
  const {user}=await authenticatedSupabase(request);const db=adminDb();
  if(!await requireModerator(db,user.id))return reply.code(403).send({error:{code:"MODERATION_FORBIDDEN",message:"Moderator access required."}});
  const {data:report}=await db.from("user_reports").select("reported_user_id").eq("id",params.data.reportId).maybeSingle();
  if(!report)return reply.code(404).send({error:{code:"REPORT_NOT_FOUND",message:"Report not found."}});
  const {error}=await db.from("user_reports").update({status:body.data.status}).eq("id",params.data.reportId);
  if(error)return reply.code(503).send({error:{code:"MODERATION_UPDATE_FAILED",message:"Report status could not be updated."}});
  await db.from("moderation_audit_log").insert({actor_id:user.id,action:"report_"+body.data.status,target_user_id:report.reported_user_id,report_id:params.data.reportId,details:{}});
  return reply.send({updated:true,status:body.data.status});
 });
 app.get("/v1/admin/moderation/audit",async(request,reply)=>{
  const {user}=await authenticatedSupabase(request);const db=adminDb();
  if(!await requireModerator(db,user.id))return reply.code(403).send({error:{code:"MODERATION_FORBIDDEN",message:"Moderator access required."}});
  const parsed=z.object({limit:z.coerce.number().int().min(1).max(100).optional()}).safeParse(request.query);
  if(!parsed.success)return reply.code(400).send({error:{code:"INVALID_QUERY",message:"Audit filters are invalid."}});
  const {data,error}=await db.from("moderation_audit_log").select("id,actor_id,action,target_user_id,report_id,sanction_id,details,created_at").order("created_at",{ascending:false}).limit(parsed.data.limit??50);
  if(error)return reply.code(503).send({error:{code:"AUDIT_READ_FAILED",message:"Audit log unavailable."}});
  return reply.send({data});
 });
 app.patch("/v1/admin/moderation/sanctions/:sanctionId/revoke",async(request,reply)=>{
  const params=z.object({sanctionId:z.string().uuid()}).safeParse(request.params);
  if(!params.success)return reply.code(400).send({error:{code:"INVALID_SANCTION",message:"Sanction id is invalid."}});
  const {user}=await authenticatedSupabase(request);const db=adminDb();
  const {data:role}=await db.from("admin_roles").select("role").eq("user_id",user.id).eq("enabled",true).maybeSingle();
  if(!role||!["admin","superadmin"].includes(role.role))return reply.code(403).send({error:{code:"SANCTION_REVOKE_FORBIDDEN",message:"Admin access required."}});
  const {data,error}=await db.from("user_sanctions").update({active:false}).eq("id",params.data.sanctionId).eq("active",true).select("id,user_id,sanction_type").maybeSingle();
  if(error)return reply.code(503).send({error:{code:"SANCTION_REVOKE_FAILED",message:"Sanction could not be revoked."}});
  if(!data)return reply.code(404).send({error:{code:"SANCTION_NOT_FOUND",message:"Active sanction not found."}});
  const {error:auditError}=await db.from("moderation_audit_log").insert({actor_id:user.id,action:"sanction_revoked",target_user_id:data.user_id,sanction_id:data.id,details:{}});
  if(auditError)return reply.code(503).send({error:{code:"AUDIT_WRITE_FAILED",message:"Sanction revoked but audit write failed; investigate immediately."}});
  return reply.send({revoked:true,id:data.id});
 });
 app.get("/v1/admin/moderation/sanctions",async(request,reply)=>{
  const {user}=await authenticatedSupabase(request);const db=adminDb();
  if(!await requireModerator(db,user.id))return reply.code(403).send({error:{code:"MODERATION_FORBIDDEN",message:"Moderator access required."}});
  const query=z.object({limit:z.coerce.number().int().min(1).max(100).optional()}).safeParse(request.query);
  if(!query.success)return reply.code(400).send({error:{code:"INVALID_QUERY",message:"Sanction filter invalid."}});
  const {data,error}=await db.from("user_sanctions").select("id,user_id,sanction_type,reason,starts_at,expires_at,active,issued_by").order("starts_at",{ascending:false}).limit(query.data.limit??50);
  if(error)return reply.code(503).send({error:{code:"SANCTION_READ_FAILED",message:"Sanctions unavailable."}});
  return reply.send({data});
 });
 app.post("/v1/admin/moderation/sanctions",async(request,reply)=>{
  const body=sanctionSchema.safeParse(request.body);if(!body.success)return reply.code(400).send({error:{code:"INVALID_SANCTION",message:"Sanction details are invalid."}});
  const {user}=await authenticatedSupabase(request);const db=adminDb();
  if(!await requireModerator(db,user.id))return reply.code(403).send({error:{code:"MODERATION_FORBIDDEN",message:"Moderator access required."}});
  if(body.data.type==="permanent_ban"&&!((await db.from("admin_roles").select("role").eq("user_id",user.id).eq("enabled",true).maybeSingle()).data?.role==="superadmin"))return reply.code(403).send({error:{code:"BAN_FORBIDDEN",message:"Only superadmins can issue permanent bans."}});
  const expiresAt=body.data.type==="temporary_suspension"&&body.data.durationHours?new Date(Date.now()+body.data.durationHours*3600000).toISOString():null;
  const {data,error}=await db.from("user_sanctions").insert({user_id:body.data.userId,sanction_type:body.data.type,reason:body.data.reason,expires_at:expiresAt,issued_by:user.id}).select("id,user_id,sanction_type,reason,starts_at,expires_at,active").single();
  if(error)return reply.code(503).send({error:{code:"SANCTION_FAILED",message:"Sanction could not be issued."}});
  await db.from("moderation_audit_log").insert({actor_id:user.id,action:"sanction_"+body.data.type,target_user_id:body.data.userId,sanction_id:data.id,details:{durationHours:body.data.durationHours??null}});
  return reply.code(201).send({data});
 });
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
 app.post("/v1/calls/:sessionId/block",async(request,reply)=>{
  const params=z.object({sessionId:z.string().uuid()}).safeParse(request.params);
  if(!params.success)return reply.code(400).send({error:{code:"INVALID_SESSION",message:"Session id is invalid."}});
  const {user,client}=await authenticatedSupabase(request);const db=adminDb();
  const {data:session,error}=await db.from("match_sessions").select("participant_a,participant_b").eq("id",params.data.sessionId).maybeSingle();
  if(error||!session)return reply.code(404).send({error:{code:"SESSION_NOT_FOUND",message:"Call session not found."}});
  const target=session.participant_a===user.id?session.participant_b:session.participant_b===user.id?session.participant_a:null;
  if(!target)return reply.code(403).send({error:{code:"CALL_NOT_AUTHORIZED",message:"You are not a participant in this call."}});
  const {data,error:blockError}=await client.rpc("user_block_create",{p_target:target});
  if(blockError)return reply.code(400).send({error:{code:"BLOCK_FAILED",message:"User could not be blocked."}});
  return reply.send({data});
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
