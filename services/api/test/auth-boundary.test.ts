import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { bearerToken, AuthenticationError } from "../src/plugins/supabase-user.js";

function request(authorization?: string) {
  return { headers: authorization === undefined ? {} : { authorization } } as any;
}

describe("API bearer authentication boundary", () => {
  it("rejects missing Authorization header", () => {
    assert.throws(() => bearerToken(request()), AuthenticationError);
  });
  it("rejects non-Bearer schemes", () => {
    for (const value of ["Basic abc", "bearer abc", "Token abc", ""]) {
      assert.throws(() => bearerToken(request(value)), AuthenticationError);
    }
  });
  it("rejects an empty Bearer token", () => {
    assert.throws(() => bearerToken(request("Bearer   ")), AuthenticationError);
  });
  it("extracts only the opaque bearer token without decoding or trusting claims", () => {
    const opaque = "eyJhbGciOiJub25lIn0.eyJzdWIiOiJhZG1pbiJ9.signature";
    assert.equal(bearerToken(request("Bearer " + opaque)), opaque);
  });
  it("trims surrounding whitespace from the token", () => {
    assert.equal(bearerToken(request("Bearer   token-value  ")), "token-value");
  });
});
