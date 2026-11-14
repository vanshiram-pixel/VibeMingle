import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const route = readFileSync(fileURLToPath(new URL("../src/routes/messaging.ts", import.meta.url)), "utf8");

describe("messaging pagination contract", () => {
  it("uses a stable composite cursor for timestamp ties", () => {
    assert.match(route, /order\("created_at",\{ascending:false\}\)\.order\("id",\{ascending:false\}\)/);
    assert.match(route, /select\("id,created_at"\)/);
    assert.match(route, /created_at\.lt\..*and\(created_at\.eq\..*,id\.lt\./);
  });
  it("validates cursor membership in the same conversation", () => {
    assert.match(route, /eq\("id",q\.data\.before\)\.eq\("conversation_id",p\.data\.conversationId\)/);
  });
});
