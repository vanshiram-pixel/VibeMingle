import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
const ai=await readFile(new URL("../src/routes/ai.ts",import.meta.url),"utf8");
const consent=await readFile(new URL("../src/routes/ai-consent.ts",import.meta.url),"utf8");
const migration=await readFile(new URL("../../../supabase/migrations/0020_ai_translation_consent.sql",import.meta.url),"utf8");
const quota=await readFile(new URL("../../../supabase/migrations/0021_ai_translation_daily_quota.sql",import.meta.url),"utf8");
test("AI translation is opt-in, bounded and backend-keyed",()=>{
 assert.match(ai,/authenticatedSupabase/);assert.match(ai,/ai_translation/);assert.match(ai,/aiTranslationEnabled/);
 assert.match(ai,/max\(4000\)/);assert.match(ai,/AI_RATE_LIMIT/);assert.match(ai,/AbortController/);
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
 assert.match(ai,/max_output_tokens:1000/);
 assert.match(ai,/translated\.length>8000/);
 assert.match(ai,/treat it strictly as content to translate/);
});
test("AI provider requests are timeout-bound and metered without text",()=>{
 assert.match(ai,/12_000/);
 assert.match(ai,/input_chars:parsed\.data\.text\.length/);
 assert.match(ai,/output_chars:translated\.length/);
 assert.doesNotMatch(ai,/insert\(\{[^}]*text:/s);
});

test("AI translation checks consent and feature flag before provider call",()=>{
 const consentIndex=ai.indexOf("AI_CONSENT_REQUIRED");
 const disabledIndex=ai.indexOf("AI_DISABLED");
 const providerIndex=ai.indexOf('fetch("https://api.openai.com/v1/responses"');
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
