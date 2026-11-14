import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { authenticatedSupabase } from "../plugins/supabase-user.js";
import { liveKitConfigured } from "../domain/video/livekit-provider.js";
const joinSchema=z.object({sessionId:z.string().uuid()}).strict();
export async function registerCallRoutes(app:FastifyInstance):Promise<void>{
 app.post("/v1/calls/token",async(request,reply)=>{
  const parsed=joinSchema.safeParse(request.body);
  if(!parsed.success)return reply.code(400).send({error:{code:"INVALID_SESSION",message:"Session id is invalid."}});
  await authenticatedSupabase(request);
  // Deliberately fail closed until server-side session/participant checks and LiveKit signing are wired.
  return reply.code(503).send({error:{code:"CALL_PROVIDER_NOT_CONFIGURED",message:"Secure call token service is not configured."}});
 });
 app.post("/v1/calls/:sessionId/leave",async(request,reply)=>{
  const params=z.object({sessionId:z.string().uuid()}).safeParse(request.params);
  if(!params.success)return reply.code(400).send({error:{code:"INVALID_SESSION",message:"Session id is invalid."}});
  await authenticatedSupabase(request);
  return reply.code(503).send({error:{code:"CALL_LIFECYCLE_NOT_CONFIGURED",message:"Call lifecycle service is not configured."}});
 });
}
