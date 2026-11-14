import test from "node:test";
import assert from "node:assert/strict";
import { requestTranslation } from "../src/lib/ai-translation-provider.js";

const ok=(payload:unknown)=>new Response(JSON.stringify(payload),{status:200,headers:{"Content-Type":"application/json"}});
test("provider sends bounded Responses request and returns translated text",async()=>{
 let requestBody:any;let auth="";
 const result=await requestTranslation({apiKey:"test-secret",model:"test-model",text:"नमस्ते",targetLanguage:"en",fetcher:async(_url,init)=>{auth=String((init?.headers as Record<string,string>).Authorization);requestBody=JSON.parse(String(init?.body));return ok({output:[{content:[{type:"output_text",text:"Hello"}]}]});}});
 assert.deepEqual(result,{ok:true,translated:"Hello"});assert.equal(auth,"Bearer test-secret");assert.equal(requestBody.model,"test-model");assert.equal(requestBody.max_output_tokens,1000);assert.match(requestBody.input[0].content,/strictly as content/);assert.match(requestBody.input[1].content,/नमस्ते/);
});
test("provider rejects non-success status without leaking response body",async()=>{
 const result=await requestTranslation({apiKey:"x",model:"m",text:"x",targetLanguage:"hi",fetcher:async()=>new Response("sensitive provider details",{status:429})});
 assert.deepEqual(result,{ok:false,kind:"provider"});
});
test("provider rejects missing or oversized output",async()=>{
 const missing=await requestTranslation({apiKey:"x",model:"m",text:"x",targetLanguage:"hi",fetcher:async()=>ok({output:[]})});
 assert.deepEqual(missing,{ok:false,kind:"invalid"});
 const oversized=await requestTranslation({apiKey:"x",model:"m",text:"x",targetLanguage:"hi",fetcher:async()=>ok({output:[{content:[{type:"output_text",text:"a".repeat(8001)}]}]})});
 assert.deepEqual(oversized,{ok:false,kind:"invalid"});
});
test("provider maps abort to timeout and network failures to sanitized provider error",async()=>{
 const timeout=await requestTranslation({apiKey:"x",model:"m",text:"x",targetLanguage:"hi",timeoutMs:5,fetcher:(_u,init)=>new Promise((_resolve,reject)=>init?.signal?.addEventListener("abort",()=>reject(new DOMException("aborted","AbortError"))))});
 assert.deepEqual(timeout,{ok:false,kind:"timeout"});
 const network=await requestTranslation({apiKey:"x",model:"m",text:"x",targetLanguage:"hi",fetcher:async()=>{throw new Error("secret network detail")}});
 assert.deepEqual(network,{ok:false,kind:"provider"});
});
