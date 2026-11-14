# Migration 0001 review notes

This migration establishes only profile, consent history, directed block edges and report metadata.

## Security behavior intended
- Profile table direct reads are self-only; public discovery must be an explicit backend projection.
- Consent history can be read by the owner but is not client-writable (trusted server only).
- Block edges are visible/manageable only by the blocker. Backend must check both directions before any match, friend, message or private-call operation.
- Reports are owner-readable receipts; create/update and moderation must use trusted server operations.
- No report evidence/blob is stored here. Evidence needs a separate access-controlled design and retention policy.

## Required validation before merge/production
- Run Supabase CLI migration against a disposable local database.
- Test anon cannot read/write all four tables.
- Test authenticated user A cannot read/update profile B, consent B, block B's edges or report B's receipt.
- Test A can create/read/update only own profile and create/remove own block edges.
- Confirm authenticated users cannot directly insert consent or reports, or mutate report status.
- Inspect grants and policies using Supabase policy catalog; test service-role/trusted API access separately.
- Add trigger/function and cascade behavior tests.
- Add API-level tests for block enforcement in all domain flows.

## Known limitation
A direct profile insert policy allows a user to create their own row, but profile bootstrap/creation should be made idempotent in the trusted onboarding flow. Production privacy/discovery policies, moderation evidence, age-assurance records, sanctions and audit tables are not included yet.
