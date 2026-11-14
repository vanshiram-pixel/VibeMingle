import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { eligibleForMatch, pairIsBlocked } from "../src/domain/matching/eligibility.js";

const ready = { profileExists:true, terms:true, privacy:true, ageAssurance:true, ageVerified:true, sanctioned:false, rateLimited:false };

describe("matching authorization policy", () => {
  it("blocks pair in either direction", () => {
    const edge=[{blockerId:"A",blockedId:"B"}];
    assert.equal(pairIsBlocked("A","B",edge),true);
    assert.equal(pairIsBlocked("B","A",edge),true);
    assert.equal(pairIsBlocked("A","C",edge),false);
  });
  it("fails closed for every required eligibility condition", () => {
    const cases=[
      ["profileExists","profile_missing"],
      ["terms","terms_missing"],
      ["privacy","privacy_missing"],
      ["ageAssurance","age_assurance_missing"],
      ["ageVerified","age_verification_required"],
      ["sanctioned","sanctioned"],
      ["rateLimited","rate_limited"],
    ] as const;
    for(const [field,reason] of cases){
      const result=eligibleForMatch({...ready,[field]:field==="sanctioned"||field==="rateLimited"?true:false});
      assert.deepEqual(result,{eligible:false,reason},field);
    }
  });
  it("allows only fully eligible account", () => {
    assert.deepEqual(eligibleForMatch(ready),{eligible:true,reason:"eligible"});
  });
});
