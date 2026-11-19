# VibeMingle V4.1 — Deployment Runbook (Pre-production)

> This repository branch is not production-ready merely because CI passes. No production service has been provisioned or deployed by this runbook.

## 1. Isolated infrastructure (required)
- Create a dedicated Supabase project for VibeMingle; never reuse the Rojgar Sathi project.
- Configure Google OAuth in Google Cloud and Supabase Auth; allow-list the exact app callback/deep-link URIs.
- Configure Supabase Realtime publication, RLS, Edge Function secrets, storage buckets and retention.
- Configure TURN (coturn or managed provider) with short-lived credentials. Do not ship TURN secrets in Flutter.
- Set up HTTPS hosting/domain, privacy policy, terms, deletion/appeal/support contacts, monitoring and backups.

## 2. Database
Apply migrations in order:
```sh
supabase link --project-ref <VIBEMINGLE_PROJECT_REF>
supabase db push
supabase migration list
```
Review policies and test with two ordinary authenticated accounts plus anon/service-role negative tests. Never expose service-role credentials to mobile/web clients.

## 3. Edge Functions
Deploy only after reviewing each function's auth and resource limits:
```sh
supabase functions deploy match-worker
```
Set required secrets in the Supabase project secret store (not GitHub source or client builds). Verify worker scheduling/cron and stale queue cleanup.

## 4. Android build
```sh
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter create --platforms=android --project-name vibe_mingle .
flutter build apk --release --dart-define=SUPABASE_URL=<URL> --dart-define=SUPABASE_PUBLISHABLE_KEY=<KEY>
```
Use a signing key held outside the repository and configure release signing before publishing. The CI artifact is an unsigned/configuration-placeholder APK, not a Play Store release.

## 5. Mandatory release gates
- Two-account OAuth, queue fairness, bilateral preferences, consent revocation and block/report tests.
- Private chat encryption/key verification, multi-device recovery, attachments and push notification security review.
- Audio/video signaling, TURN relay, reconnect, permissions and abuse/timeout tests on real Android devices and networks.
- RLS and RPC authorization tests; no unauthorized session/message reads or actions.
- Moderation appeals, age/eligibility safeguards, privacy notice, data deletion/export, incident response, backup restore drill.
- Web/PWA and Admin/Ops console built, security-tested and deployed separately; verify least-privilege roles and immutable audit events.
- CI green (format, analyzer, tests, Android build), dependency/security scans, rollback plan and monitoring.

## Release status
- Git branch: `feat/typing-presence`
- CI validates Flutter source; Android scaffold/build is generated in CI.
- No dedicated VibeMingle Supabase project, OAuth credentials, TURN service, web/admin deployment or production release is confirmed here.
- Production deployment and launch require explicit owner approval after all gates pass.
