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
