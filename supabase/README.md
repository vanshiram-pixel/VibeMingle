# Supabase database foundation

- Put reviewed SQL migrations under `migrations/` in chronological order.
- Use local Supabase CLI for migration validation and reset in development.
- Enable RLS for user-facing tables; write explicit policies and tests.
- Never commit service-role keys or production credentials.
- Production data changes require backup, reviewed migration, rollout and rollback plan.

No schema or RLS policy is production-approved yet; do not create sensitive tables without a matching access model and tests.
