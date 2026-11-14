import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { authenticatedSupabase } from "../plugins/supabase-user.js";
const requestSchema=z.object({targetUserId:z.string().uuid()}).strict();
export async function registerSocialRoutes(app:FastifyInstance):Promise<void>{
 app.post("/v1/friends/requests",async(request,reply)=>{
  const parsed=requestSchema.safeParse(request.body);if(!parsed.success)return reply.code(400).send({error:{code:"INVALID_TARGET",message:"Target user id is invalid."}});
  const {user,client}=await authenticatedSupabase(request);if(user.id===parsed.data.targetUserId)return reply.code(400).send({error:{code:"SELF_REQUEST",message:"You cannot friend yourself."}});
  // Fail closed until trusted transaction enforces blocks, sanctions, duplicates and rate limits.
  const {data,error}=await client.rpc("friend_request_create",{p_target:parsed.data.targetUserId});
  if(error)return reply.code(error.code==="PGRST202"?501:400).send({error:{code:"FRIEND_REQUEST_UNAVAILABLE",message:"Friend request service is not configured."}});
  return reply.code(201).send({data});
 });
 app.get("/v1/friends/requests",async(request,reply)=>{
  const {user,client}=await authenticatedSupabase(request);
  const {data,error}=await client.from("friend_requests").select("id,sender_id,receiver_id,status,created_at").or(`sender_id.eq.${user.id},receiver_id.eq.${user.id}`).order("created_at",{ascending:false}).limit(100);
  if(error)return reply.code(400).send({error:{code:"FRIEND_REQUESTS_READ_FAILED",message:"Friend requests unavailable."}});
  return reply.send({data});
 });
 app.get("/v1/friends",async(request,reply)=>{
  await authenticatedSupabase(request);
  return reply.code(501).send({error:{code:"FRIENDS_NOT_CONFIGURED",message:"Friend list projection with block filtering is not configured."}});
 });
}
