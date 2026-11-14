import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { authenticatedSupabase } from "../plugins/supabase-user.js";
import { LocalMatchQueue } from "../domain/matching/queue.js";
const queue=new LocalMatchQueue();
const preferences=z.object({region:z.string().max(12).optional(),language:z.string().max(12).optional(),interests:z.array(z.string().max(32)).max(10).optional(),genderFilter:z.enum(["any","women","men","other"]).optional()}).strict();
export async function registerMatchingRoutes(app:FastifyInstance):Promise<void>{
 app.post("/v1/matching/queue",async(request,reply)=>{
  const parsed=preferences.safeParse(request.body??{});if(!parsed.success)return reply.code(400).send({error:{code:"MATCH_PREFS_INVALID",message:"Matching preferences are invalid."}});
  const {user}=await authenticatedSupabase(request);
  // Eligibility/consent/block/sanction checks must be completed by trusted production
  // matching service before queue admission. This local adapter is intentionally disabled.
  return reply.code(501).send({error:{code:"MATCHING_NOT_CONFIGURED",message:"Production queue adapter and eligibility checks are not configured."}});
 });
 app.delete("/v1/matching/queue",async(request,reply)=>{
  const {user}=await authenticatedSupabase(request);queue.remove(user.id);return reply.code(204).send();
 });
}
