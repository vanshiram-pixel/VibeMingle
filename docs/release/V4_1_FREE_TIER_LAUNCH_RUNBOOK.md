# VibeMingle V4.1 — Full launch execution plan (free-tier first)

**Planning baseline:** 15 Nov 2026, local India time. Target is a reviewable release candidate, not an unconditional same-day production launch. A full social/video product cannot honestly be declared launch-ready until external credentials, two-device QA, provider configuration and abuse/security checks pass.

## Workstream batches (large, cohesive)
1. **Platform & CI gate** — Flutter formatting/analyze/tests; build artifacts; dependency/license review; environment separation. (CI workflow added; first run pending.)
2. **Identity & account lifecycle** — Google OAuth provider/redirects, account deletion, profile onboarding, consent and eligibility, recovery/session handling.
3. **Social graph & privacy** — friends/follow/fans, discovery filters, block propagation, profile RLS, pagination and abuse limits.
4. **Messaging product** — client-side cryptography integration, device key lifecycle, ciphertext-only transport, attachments, delivery/read receipts, realtime reconnect and multi-device protocol. Existing additive SQL is not a complete E2EE implementation; legacy plaintext route must be disabled only after migration and compatibility plan.
5. **Matching + calls** — server worker/atomic pairing, eligibility/consent, queue heartbeats, bilateral filters, session state events, WebRTC signaling, TURN credentials, call controls and two-device test.
6. **Translation & safety** — consented translation/captions, fallback, report/block, case-scoped evidence, moderation workflows, rate limits and emergency controls.
7. **Wallet/VIP/rewards/admin** — payment-provider sandbox, ledger idempotency, entitlement enforcement, campaign/reward abuse limits, admin audit and support.
8. **Release candidate** — migrations dry-run/staging, clean install, OAuth on Android+web, chat E2EE, match/video/audio, block/report, reconnect/offline, accessibility, performance, security and regression matrix.
9. **Launch gate** — configure real secrets and DNS, privacy/terms, store/domain review, rollback, alerts, backups and incident contacts. Obtain owner approval before production promotion.

## Free-tier policy
Use free tiers only where current quotas, regional availability, retention, bandwidth and provider terms permit. WebRTC TURN, media/translation, push, OAuth, payments and high-volume realtime can exceed free allowances. Never silently turn on paid billing; document quota limits and ask before any nonzero cost.

## Evidence ledger
- **Implemented in Git:** source/migration/docs commits.
- **CI verified:** only after an actual successful GitHub Actions run.
- **Staging verified:** only after migration and integration checks on the correct VibeMingle Supabase project.
- **Release candidate:** only after all critical tests and owner review.
- **Production launched:** only after explicit owner approval and a confirmed deployment URL/health check.

## Current integration warning
The connected Supabase account currently lists a project named vanshiram@gmail.com (ref krvnpgpsjolsfhjyihan) whose applied migrations/tables are Rojgar Sathi. **It is not identified as VibeMingle.** No VibeMingle migrations were applied to that project. Locate/create the correct VibeMingle backend before staging execution.
