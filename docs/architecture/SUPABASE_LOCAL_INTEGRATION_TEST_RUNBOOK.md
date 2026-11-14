# Supabase Local Integration Test Runbook (VibeMingle)

Branch: `spec/v3-integrated-master-draft`
Status: local test harness instructions; not a claim that local Docker tests have already run.

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

## Current repo caveat
At audit time the Supabase directory contains migrations and a README but no `supabase/config.toml` and no executable pgTAP SQL tests. Thus `supabase start/db reset` may not work until CLI config and local test harness are added. Do not infer successful DB validation from static API tests.

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

## CI integration next
Use a dedicated local Supabase GitHub Actions job with Docker/service support and disposable database. Pin CLI version; run `supabase start`, `supabase db reset`, SQL tests and API integration tests, then stop services. Add only after config and tests are present. This document alone does not create that workflow.
