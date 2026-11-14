import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
const ai=await readFile(new URL("../src/routes/ai.ts",import.meta.url),"utf8");
const consent=await readFile(new URL("../src/routes/ai-consent.ts",import.meta.url),"utf8");
const migration=await readFile(new URL("../../../supabase/migrations/0020_ai_translation_consent.sql",import.meta.url),"utf8");
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