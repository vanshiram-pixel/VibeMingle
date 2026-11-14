import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
const ai=await readFile(new URL("../src/routes/ai.ts",import.meta.url),"utf8");
const provider=await readFile(new URL("../src/lib/ai-translation-provider.ts",import.meta.url),"utf8");
const consent=await readFile(new URL("../src/routes/ai-consent.ts",import.meta.url),"utf8");
const migration=await readFile(new URL("../../../supabase/migrations/0020_ai_translation_consent.sql",import.meta.url),"utf8");
const quota=await readFile(new URL("../../../supabase/migrations/0021_ai_translation_daily_quota.sql",import.meta.url),"utf8");
const rate=await readFile(new URL("../../../supabase/migrations/0022_ai_translation_distributed_rate_limit.sql",import.meta.url),"utf8");
test("AI translation is opt-in, bounded and backend-keyed",()=>{
 assert.match(ai,/authenticatedSupabase/);assert.match(ai,/ai_translation/);assert.match(ai,/aiTranslationEnabled/);
 assert.match(ai,/max\(4000\)/);assert.match(ai,/AI_RATE_LIMIT/);assert.match(provider,/AbortController/);
 assert.match(ai,/OPENAI_API_KEY|openaiApiKey/);assert.doesNotMatch(ai,/console\.(log|info).*parsed\.data\.text/);
});
test("AI consent endpoint supports status and immutable grant/withdraw history",()=>{
 assert.match(consent,/GET|app\.get/);assert.match(consent,/app\.put/);assert.match(consent,/user_consents/);
 assert.match(consent,/supabaseServiceRoleKey/);assert.match(consent,/authenticatedSupabase/);
});
test("AI usage ledger never stores source or translated content",()=>{
 assert.match(migration,/input_chars/);assert.match(migration,/output_chars/);assert.doesNotMatch(migration,/translated_text|source_text|message_body/);
 assert.match(migration,/enable row level security/i);assert.match(migration,/revoke all.*authenticated/i);
});
test("AI daily quota is atomic, bounded, and service-role only",()=>{
 assert.match(ai,/consume_ai_translation_quota/);assert.match(ai,/AI_DAILY_LIMIT/);assert.match(ai,/AI_METERING_FAILED/);
 assert.match(quota,/requests < 30/);assert.match(quota,/input_chars\+p_input_chars <= 30000/);
 assert.match(quota,/security definer/i);assert.match(quota,/revoke all on function.*authenticated/i);
});

test("AI translation rejects unsupported language codes and caps provider output",()=>{
 assert.match(ai,/const allowed=new Set/);
 assert.match(ai,/allowed\.has/);
 assert.match(provider,/max_output_tokens:1000/);
 assert.match(provider,/translated\.length>8000/);
 assert.match(provider,/treat it strictly as content to translate/);
});
test("AI provider requests are timeout-bound and metered without text",()=>{
 assert.match(provider,/12_000/);
 assert.match(ai,/input_chars:parsed\.data\.text\.length/);
 assert.match(ai,/output_chars:translated\.length/);
 assert.doesNotMatch(ai,/insert\(\{[^}]*text:/s);
});

test("AI translation checks consent and feature flag before provider call",()=>{
 const consentIndex=ai.indexOf("AI_CONSENT_REQUIRED");
 const disabledIndex=ai.indexOf("AI_DISABLED");
 const providerIndex=ai.indexOf("requestTranslation(");
 assert.ok(consentIndex>0 && disabledIndex>consentIndex && providerIndex>disabledIndex);
 assert.match(ai,/aiTranslationEnabled/);
});
test("AI translation fails closed when quota or usage metering is unavailable",()=>{
 assert.match(ai,/AI_QUOTA_UNAVAILABLE/);
 assert.match(ai,/AI_METERING_FAILED/);
 assert.match(ai,/if\(meterError\)return reply\.code\(503\)/);
});
test("AI translation errors do not expose provider response bodies",()=>{
 assert.match(ai,/AI_PROVIDER_ERROR/);
 assert.match(ai,/AI_TIMEOUT/);
 assert.doesNotMatch(ai,/response\.text\(\).*reply|payload\.error\.message/);
});


test("AI rate limiter is shared across API instances and atomic in database",()=>{
 assert.match(ai,/consume_ai_translation_rate_limit/);
 assert.match(ai,/AI_RATE_LIMIT_UNAVAILABLE/);
 assert.doesNotMatch(ai,/new Map/);
 assert.match(rate,/user_id uuid primary key/i);
 assert.match(rate,/requests < 8/);
 assert.match(rate,/interval/);
 assert.match(rate,/security definer/i);
 assert.match(rate,/grant execute on function public\.consume_ai_translation_rate_limit\(uuid\) to service_role/i);
 assert.match(rate,/enable row level security/i);
});

test("AI quota uses UTC day buckets and rejects invalid character counts",()=>{
 assert.match(quota,/timezone/i); assert.match(quota,/utc/i); assert.match(quota,/::date/i);
 assert.match(quota,/primary key\(user_id,quota_date\)/i);
 assert.match(quota,/p_input_chars < 1 or p_input_chars > 4000/i);
 assert.match(quota,/input_chars\+p_input_chars <= 30000/i);
 assert.match(quota,/grant execute on function public\.consume_ai_translation_quota\(uuid,integer\) to service_role/i);
});


test("AI translation applies consent, feature, rate and quota gates before provider spend",()=>{
 const consent=ai.indexOf("AI_CONSENT_REQUIRED");
 const disabled=ai.indexOf("AI_DISABLED");
 const rate=ai.indexOf("consume_ai_translation_rate_limit");
 const quota=ai.indexOf("consume_ai_translation_quota");
 const providerCall=ai.indexOf("requestTranslation(");
 assert.ok(consent>0 && disabled>consent && rate>disabled && quota>rate && providerCall>quota);
 assert.match(ai,/if\(rateError\)return reply\.code\(503\)/);
 assert.match(ai,/if\(!rateAllowed\)return reply\.code\(429\)/);
 assert.match(ai,/if\(quotaError\)return reply\.code\(503\)/);
 assert.match(ai,/if\(!quota\)return reply\.code\(429\)/);
});

test("AI translation records usage only after a valid provider result",()=>{
 const providerCall=ai.indexOf("requestTranslation(");
 const meter=ai.lastIndexOf("ai_translation_usage");
 const meterInsert=ai.indexOf(".insert({user_id:user.id,provider:");
 const response=ai.indexOf("return reply.send({data:{translated");
 assert.ok(providerCall>0 && meter>providerCall && meterInsert>meter && response>meterInsert);
 assert.match(ai,/if\(meterError\)return reply\.code\(503\)/);
});
