import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const route = readFileSync(fileURLToPath(new URL("../src/routes/messaging.ts", import.meta.url)), "utf8");
const migration = readFileSync(fileURLToPath(new URL("../../../supabase/migrations/0024_message_report_rpc.sql", import.meta.url)), "utf8");

describe("message report safety contract", () => {
  it("exposes report endpoint with strict allowed categories and bounded description", () => {
    assert.match(route, /\/v1\/messages\/:messageId\/report/);
    assert.match(route, /z\.enum\(\["harassment","sexual_content","minor_safety","spam","hate","violence","impersonation","scam","other"\]\)/);
    assert.match(route, /description:z\.string\(\)\.max\(2000\)/);
    assert.match(route, /rpc\("message_report"/);
  });
  it("derives reporter and reported user from auth and message membership", () => {
    assert.match(migration, /v_actor uuid := auth\.uid\(\)/);
    assert.match(migration, /cm\.user_id=v_actor and m\.sender_id<>v_actor/);
    assert.match(migration, /v_actor, v_message\.sender_id, p_category, btrim\(p_description\), 'message', v_message\.id/);
    assert.match(migration, /revoke all on function public\.message_report\(uuid,text,text\) from public,anon/);
    assert.match(migration, /grant execute on function public\.message_report\(uuid,text,text\) to authenticated/);
  });
});
