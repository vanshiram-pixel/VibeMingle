import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { buildServer } from "../src/server.js";

describe("authenticated API route boundary (no Supabase network)", () => {
  it("rejects missing bearer token on protected routes", async () => {
    const app=await buildServer();
    try {
      for(const path of ["/v1/me","/v1/matching/status","/v1/calls/active"]){
        const response=await app.inject({method:"GET",url:path});
        assert.equal(response.statusCode,401,path);
      }
    } finally { await app.close(); }
  });
  it("rejects malformed bearer scheme before Supabase auth", async () => {
    const app=await buildServer();
    try {
      const response=await app.inject({method:"GET",url:"/v1/me",headers:{authorization:"Basic abc"}});
      assert.equal(response.statusCode,401);
    } finally { await app.close(); }
  });
});
