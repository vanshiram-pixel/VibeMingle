import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { authenticatedSupabase } from "../plugins/supabase-user.js";
import { env } from "../config/env.js";
import { requestTranslation } from "../lib/ai-translation-provider.js";

const schema=z.object({text:z.string().trim().min(1).max(4000),targetLanguage:z.string().regex(/^[a-z]{2,3}(-[A-Z]{2})?$/)}).strict();
const allowed=new Set(["en","hi","es","fr","de","pt","ar","ja","ko","zh","ru","it","id","bn","ur","tr","th","vi"]);
export async function registerAiRoutes(app:FastifyInstance){
 app.post("/v1/ai/translate",async(request,reply)=>{
  const parsed=schema.safeParse(request.body);
  if(!parsed.success||!allowed.has(parsed.data?.targetLanguage??""))return reply.code(400).send({error:{code:"INVALID_TRANSLATION",message:"Text or target language is invalid."}});
  const {user,client}=await authenticatedSupabase(request);
  const {data:consent,error:consentError}=await client.from("user_consents").select("granted,withdrawn_at").eq("user_id",user.id).eq("purpose","ai_translation").order("recorded_at",{ascending:false}).limit(1).maybeSingle();
  if(consentError)return reply.code(503).send({error:{code:"CONSENT_UNAVAILABLE",message:"AI consent could not be checked."}});
  if(!consent?.granted||consent.withdrawn_at)return reply.code(403).send({error:{code:"AI_CONSENT_REQUIRED",message:"Enable AI translation consent before using this feature."}});
  if(!env.openaiApiKey||!env.aiTranslationEnabled)return reply.code(503).send({error:{code:"AI_DISABLED",message:"AI translation is currently unavailable."}});
  if(!env.supabaseServiceRoleKey||!env.supabaseUrl)return reply.code(503).send({error:{code:"AI_QUOTA_UNAVAILABLE",message:"AI usage controls are unavailable."}});
  const {createClient}=await import("@supabase/supabase-js");
  const admin=createClient(env.supabaseUrl,env.supabaseServiceRoleKey,{auth:{persistSession:false}});
  const {data:rateAllowed,error:rateError}=await admin.rpc("consume_ai_translation_rate_limit",{p_user_id:user.id});
  if(rateError)return reply.code(503).send({error:{code:"AI_RATE_LIMIT_UNAVAILABLE",message:"AI rate controls are unavailable."}});
  if(!rateAllowed)return reply.code(429).send({error:{code:"AI_RATE_LIMIT",message:"Translation limit reached. Try again shortly."}});
  const {data:quota,error:quotaError}=await admin.rpc("consume_ai_translation_quota",{p_user_id:user.id,p_input_chars:parsed.data.text.length});
  if(quotaError)return reply.code(503).send({error:{code:"AI_QUOTA_UNAVAILABLE",message:"AI usage controls are unavailable."}});
  if(!quota)return reply.code(429).send({error:{code:"AI_DAILY_LIMIT",message:"Daily translation limit reached."}});
  const result=await requestTranslation({apiKey:env.openaiApiKey,model:env.aiTranslationModel,text:parsed.data.text,targetLanguage:parsed.data.targetLanguage});
  if(!result.ok){
   if(result.kind==="timeout")return reply.code(504).send({error:{code:"AI_TIMEOUT",message:"Translation timed out. Please retry."}});
   if(result.kind==="invalid")return reply.code(502).send({error:{code:"AI_INVALID_RESPONSE",message:"Translation could not be completed."}});
   return reply.code(502).send({error:{code:"AI_PROVIDER_ERROR",message:"Translation provider failed."}});
  }
  const translated=result.translated;
  // Metering contains character counts only; no content is persisted or logged.
  const {error:meterError}=await admin.from("ai_translation_usage").insert({user_id:user.id,provider:"openai",input_chars:parsed.data.text.length,output_chars:translated.length});
  if(meterError)return reply.code(503).send({error:{code:"AI_METERING_FAILED",message:"Usage could not be recorded."}});
  return reply.send({data:{translated,targetLanguage:parsed.data.targetLanguage}});
 });
}
