# Local Supabase CI — known migration blockers (2026-11-14)

The first disposable local Supabase replay was intentionally enabled and exposed real SQL defects. It has NOT passed yet.

## Found and fixed on branch
1. Migration 0009 referenced `public.user_sanctions` before migration 0015 created it. Removed premature predicate; 0010 already replaces discovery function and notes sanctions handling separately.
   - Fix commit: `5a8e5120`
2. Migration 0014 `matching_queue_status` function used a single `$` delimiter instead of `$$`, causing PostgreSQL syntax failure.
   - Fix commit: `e8ba96e8`

## Next observed failure
Local replay at commit `218108c6` failed on migration 0014 with the delimiter defect above. A rerun against the later commit is queued/not yet verified at the time of this note.

## Evidence boundary
- V3 CI and Repository CI passed at `e8ba96e8`.
- Supabase local replay is separate and currently **not green**.
- Continue fixing migration errors until `supabase db reset` and SQL smoke assertions both pass. Do not apply any migrations to hosted/production Supabase.


## Verified local database and RLS results (latest)

- Migration replay 0001–0017: PASS on disposable local Supabase.
- Schema smoke assertions 0018: PASS.
- Authenticated two-user isolation test 0019: PASS (12 checks) using native SQL assertions; no pgTAP dependency.
- GitHub Actions Supabase Local DB Smoke: PASS, run [43601066824](https://github.com/vanshiram-pixel/VibeMingle/actions/runs/43601066824), commit `0f118686`.
- Repository CI: PASS [43601066828](https://github.com/vanshiram-pixel/VibeMingle/actions/runs/43601066828).
- V3 CI: PASS [43601066853](https://github.com/vanshiram-pixel/VibeMingle/actions/runs/43601066853).

RLS coverage is targeted at profile/consent/block/report read isolation, profile insert forgery, and report insert restriction. This is not a full security audit, IDOR/API test, or production verification. Hosted Supabase remains untouched.


## API policy/unit test follow-up (Nov 14)

- Added bearer-token boundary tests (missing/wrong scheme/empty/opaque token/trim behavior).
- Added matching eligibility tests covering profile, terms/privacy, age assurance + verified age, sanctions, rate limits, and symmetric block edges.
- API test suite: 20 tests PASS; V3 CI [43603030071](https://github.com/vanshiram-pixel/VibeMingle/actions/runs/43603030071).
- A temporary Fastify protected-route harness surfaced a 500-vs-401 mapping discrepancy; explicit AuthenticationError mapping was added in server error handling. The harness was removed because it didn't reliably reproduce the production server setup. Treat this as a fix requiring a future end-to-end API server test—not as independently integration-verified.
- No authenticated Supabase API/IDOR integration has been run yet. Current evidence is local DB RLS + API unit/static contracts only.
