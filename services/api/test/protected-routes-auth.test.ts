import Fastify from "fastify";
import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { registerMeRoutes } from "../src/routes/me.js";
import { registerMatchingRoutes } from "../src/routes/matching.js";
import { registerSocialRoutes } from "../src/routes/social.js";
import { registerCallRoutes } from "../src/routes/calls.js";

async function testApp(){
 const app=Fastify({logger:false});\n app.setErrorHandler((error,request,reply)=>reply.code((error as any).statusCode??500).send({error:{code:"REQUEST_ERROR"}}));
 await app.register(registerMeRoutes);
 await app.register(registerMatchingRoutes);
 await app.register(registerSocialRoutes);
 await app.register(registerCallRoutes);
 return app;
}
describe("protected API route authentication boundary",()=>{
 it("rejects requests without bearer auth before database access",async()=>{
  const app=await testApp();
  try {
   for(const path of ["/v1/me","/v1/matching/status","/v1/social/friends","/v1/calls/active"]){
    const res=await app.inject({method:"GET",url:path});
    assert.equal(res.statusCode,401,path);
   }
  } finally {await app.close();}
 });
 it("rejects malformed auth scheme before Supabase access",async()=>{
  const app=await testApp();
  try {
   const res=await app.inject({method:"GET",url:"/v1/me",headers:{authorization:"Basic abc"}});
   assert.equal(res.statusCode,401);
  } finally {await app.close();}
 });
});
