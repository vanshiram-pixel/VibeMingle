# Supabase Local Integration Test Runbook (VibeMingle)

Branch: `spec/v3-integrated-master-draft`
Status: local CI harness is implemented and verified; broader API/security coverage remains pending.

## Purpose
Validate migrations 0001–0017 and RLS using a disposable local Supabase/Postgres stack. Never point this at production.

## Prerequisites
- Docker Desktop/Engine running.
- Supabase CLI installed and available as `supabase`.
- Node/npm available for API tests.
- No production URL or service-role secret in shell history or CI logs.

## First-time setup
1. From repository root: `supabase start`.
2. Inspect local services and credentials: `supabase status` (keep output private).
3. Confirm `supabase/config.toml` exists and project config is reviewed. If absent, initialize only after reviewing generated files: `supabase init`.
4. Apply migrations to local disposable DB only: `supabase db reset`. This drops/recreates the local DB; never run against production.
5. Validate migration state: `supabase migration list`.
6. Stop local stack when finished: `supabase stop`.

## Current verified state
- GitHub Actions workflow `.github/workflows/supabase-local.yml` starts disposable local Supabase, resets/replays migrations 0001–0017, runs SQL smoke test 0018 and authenticated RLS test 0019, then stops the stack.
- Verified PASS at commit `0f118686`: [Supabase Local DB Smoke run](https://github.com/vanshiram-pixel/VibeMingle/actions/runs/43601066824).
- Test 0019 uses native SQL assertions (no pgTAP extension dependency) and transaction rollback; it checks 12 identity/privacy conditions.
- The test is limited coverage, not full API/IDOR/security or hosted-production verification.

## Required database checks (test-only users)
- Migration replay from empty database succeeds, including functions/grants.
- Anonymous role has no access to private profiles, consent, blocks, reports, moderation tables, sanctions or audit.
- Authenticated user A cannot read/write user B's private rows or report receipt.
- Report status and sanctions cannot be directly client-mutated.
- Service-role operations succeed only through trusted API/RPC paths.
- RPC audit mutation rolls back entirely if audit insertion fails (no partial state).
- Rate-limit RPC increments atomically under concurrent requests; threshold semantics and reset window verified.
- Block exclusion is enforced in matching, social, messaging/private call entry points.
- Sanctioned users fail matching and call-token issuance (fail closed).
- Moderator/admin/superadmin action matrix; permanent sanction superadmin only.
- Verify function EXECUTE grants and RLS policy catalog.

## Test evidence to record
- CLI version, migration list, command exit codes, test suite result, sanitized logs, date and commit SHA.
- Never store keys, access tokens, user data or raw production logs in artifacts.

## CI integration and next coverage
The local database workflow is active and pinned to Supabase CLI 2.54.11. Next add API-level tests for IDOR, authorization/AAL2, matching/block race conditions, rate limits, audit atomicity and sanctions. Hosted Supabase remains untouched.
