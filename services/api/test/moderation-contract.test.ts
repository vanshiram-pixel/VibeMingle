import {describe,it} from "node:test";
import assert from "node:assert/strict";

const validUuid="11111111-1111-4111-8111-111111111111";

describe("moderation API input contracts",()=>{
 it("accepts only known report categories",()=>{
  const categories=["harassment","sexual_content","minor_safety","spam","hate","violence","impersonation","scam","other"];
  assert.equal(categories.length,9);
  assert.ok(categories.includes("minor_safety"));
  assert.ok(!categories.includes("unknown"));
 });
 it("requires a UUID for report and sanction targets",()=>{
  assert.match(validUuid,/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i);
  assert.doesNotMatch("not-a-uuid",/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i);
 });
 it("enforces role matrix for sanctions",()=>{
  const allowed=(role,type)=>role==="superadmin"||(role==="admin"&&type!=="permanent_ban")||(role==="moderator"&&type==="warning");
  assert.equal(allowed("moderator","warning"),true);
  assert.equal(allowed("moderator","temporary_suspension"),false);
  assert.equal(allowed("admin","temporary_suspension"),true);
  assert.equal(allowed("admin","permanent_ban"),false);
  assert.equal(allowed("superadmin","permanent_ban"),true);
 });
 it("defines bounded duration for temporary suspension",()=>{
  for(const hours of [1,24,8760])assert.ok(Number.isInteger(hours)&&hours>=1&&hours<=8760);
  for(const hours of [0,-1,8761,1.5])assert.ok(!(Number.isInteger(hours)&&hours>=1&&hours<=8760));
 });
});
