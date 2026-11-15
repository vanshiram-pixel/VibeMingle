import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { authenticatedSupabase } from "../plugins/supabase-user.js";

const uuid=z.string().uuid();
const openSchema=z.object({friendId:uuid}).strict();
const sendSchema=z.object({body:z.string().trim().min(1).max(4000)}).strict();
const editSchema=z.object({body:z.string().trim().min(1).max(4000)}).strict();
const idSchema=z.object({messageId:uuid}).strict();
const conversationSchema=z.object({conversationId:uuid}).strict();
const reportSchema=z.object({category:z.enum(["harassment","sexual_content","minor_safety","spam","hate","violence","impersonation","scam","other"]),description:z.string().max(2000).optional().default("")}).strict();
function rpcFail(reply:any,error:{code?:string}){
 const status=error.code==="28000"?401:error.code==="42501"?403:error.code==="22023"?400:400;
 return reply.code(status).send({error:{code:status===401?"UNAUTHENTICATED":status===403?"MESSAGE_FORBIDDEN":"MESSAGE_ACTION_FAILED",message:status===403?"This messaging action is not allowed.":"Messaging action could not be completed."}});
}
export async function registerMessagingRoutes(app:FastifyInstance){
 app.post("/v1/conversations",async(request,reply)=>{
  const p=openSchema.safeParse(request.body);if(!p.success)return reply.code(400).send({error:{code:"INVALID_FRIEND",message:"Friend id is invalid."}});
  const {user,client}=await authenticatedSupabase(request);if(user.id===p.data.friendId)return reply.code(400).send({error:{code:"SELF_CONVERSATION",message:"Cannot message yourself."}});
  const {data,error}=await client.rpc("conversation_open",{p_friend:p.data.friendId});if(error)return rpcFail(reply,error);return reply.code(201).send({data:{id:data}});
 });
 app.get("/v1/conversations",async(request,reply)=>{
  const {user,client}=await authenticatedSupabase(request);
  const {data,error}=await client.from("conversation_members").select("conversation_id,last_read_at,conversations(id,user_a,user_b,created_at,updated_at)").eq("user_id",user.id).order("last_read_at",{ascending:false});
  if(error)return reply.code(400).send({error:{code:"CONVERSATIONS_READ_FAILED",message:"Conversations unavailable."}});
  return reply.send({data});
 });
 app.get("/v1/conversations/:conversationId/messages",async(request,reply)=>{
  const p=conversationSchema.safeParse(request.params);const q=z.object({before:uuid.optional(),limit:z.coerce.number().int().min(1).max(100).optional()}).safeParse(request.query);
  if(!p.success||!q.success)return reply.code(400).send({error:{code:"INVALID_QUERY",message:"Message cursor or conversation id is invalid."}});
  const {user,client}=await authenticatedSupabase(request);
  const {data:member,error:me}=await client.from("conversation_members").select("conversation_id").eq("conversation_id",p.data.conversationId).eq("user_id",user.id).maybeSingle();
  if(me||!member)return reply.code(403).send({error:{code:"CONVERSATION_FORBIDDEN",message:"Conversation unavailable."}});
  let query=client.from("messages").select("id,conversation_id,sender_id,body,created_at,edited_at,deleted_at").eq("conversation_id",p.data.conversationId).order("created_at",{ascending:false}).order("id",{ascending:false}).limit(q.data.limit??50);
  if(q.data.before){const {data:cursor,error:cursorError}=await client.from("messages").select("id,created_at").eq("id",q.data.before).eq("conversation_id",p.data.conversationId).maybeSingle();if(cursorError)return reply.code(503).send({error:{code:"MESSAGE_CURSOR_UNAVAILABLE",message:"Message pagination is temporarily unavailable."}});if(!cursor)return reply.code(400).send({error:{code:"INVALID_CURSOR",message:"Message cursor not found."}});query=query.or(`created_at.lt.${cursor.created_at},and(created_at.eq.${cursor.created_at},id.lt.${cursor.id})`);}
  const {data,error}=await query;if(error)return reply.code(400).send({error:{code:"MESSAGES_READ_FAILED",message:"Messages unavailable."}});
  return reply.send({data:(data??[]).reverse()});
 });
 app.post("/v1/conversations/:conversationId/messages",async(request,reply)=>{
  const p=conversationSchema.safeParse(request.params);const b=sendSchema.safeParse(request.body);if(!p.success||!b.success)return reply.code(400).send({error:{code:"INVALID_MESSAGE",message:"Message body or conversation id is invalid."}});
  const {client}=await authenticatedSupabase(request);const {data,error}=await client.rpc("message_send",{p_conversation:p.data.conversationId,p_body:b.data.body});if(error)return rpcFail(reply,error);return reply.code(201).send({data});
 });
 app.patch("/v1/messages/:messageId",async(request,reply)=>{
  const p=idSchema.safeParse(request.params);const b=editSchema.safeParse(request.body);if(!p.success||!b.success)return reply.code(400).send({error:{code:"INVALID_MESSAGE",message:"Message id or body is invalid."}});
  const {client}=await authenticatedSupabase(request);const {data,error}=await client.rpc("message_edit",{p_message:p.data.messageId,p_body:b.data.body});if(error)return rpcFail(reply,error);return reply.send({data});
 });
 app.delete("/v1/messages/:messageId",async(request,reply)=>{
  const p=idSchema.safeParse(request.params);if(!p.success)return reply.code(400).send({error:{code:"INVALID_MESSAGE",message:"Message id is invalid."}});
  const {client}=await authenticatedSupabase(request);const {data,error}=await client.rpc("message_delete",{p_message:p.data.messageId});if(error)return rpcFail(reply,error);if(!data)return reply.code(404).send({error:{code:"MESSAGE_NOT_FOUND",message:"Message unavailable."}});return reply.send({data:{deleted:true}});
 });
 app.post("/v1/messages/:messageId/report",async(request,reply)=>{
  const p=idSchema.safeParse(request.params);const b=reportSchema.safeParse(request.body);
  if(!p.success||!b.success)return reply.code(400).send({error:{code:"INVALID_REPORT",message:"Report category, description or message id is invalid."}});
  const {client}=await authenticatedSupabase(request);
  const {data,error}=await client.rpc("message_report",{p_message:p.data.messageId,p_category:b.data.category,p_description:b.data.description});
  if(error)return rpcFail(reply,error);
  return reply.code(201).send({data:{reportId:data,status:"submitted"}});
 });
 app.post("/v1/conversations/:conversationId/read",async(request,reply)=>{
  const p=conversationSchema.safeParse(request.params);if(!p.success)return reply.code(400).send({error:{code:"INVALID_CONVERSATION",message:"Conversation id is invalid."}});
  const {client}=await authenticatedSupabase(request);const {data,error}=await client.rpc("conversation_mark_read",{p_conversation:p.data.conversationId});if(error)return rpcFail(reply,error);if(!data)return reply.code(403).send({error:{code:"CONVERSATION_FORBIDDEN",message:"Conversation unavailable."}});return reply.send({data:{read:true}});
 });
}
