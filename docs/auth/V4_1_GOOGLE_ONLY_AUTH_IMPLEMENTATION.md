# V4.1 Google-only Auth — implementation checklist

Status: SPECIFIED / current app still email-password (not compliant)
Scope: Replace existing email/password UI with Google OAuth only.

## Current source evidence
- `apps/mobile/lib/src/app.dart` contains email/password text fields, sign-up toggle and `signInWithPassword`/`signUp`.
- `apps/mobile/pubspec.yaml` uses `supabase_flutter: ^2.8.0`.
- This current screen violates the locked Google-only sign-in decision.

## Required client change
- One primary action: Continue with Google.
- Use Supabase Auth OAuth provider `google`; no password, email signup, magic-link or alternate provider controls.
- Handle OAuth launch, callback, cancellation, loading, provider/network errors and session restoration.
- Do not trust profile/name/email values from the client as authorization; verify Supabase JWT server-side.
- Account creation vs return login is automatic from the verified OAuth identity.
- After callback, route to onboarding/profile completion if required; otherwise authenticated home.
- Keep logout/session revocation available in account settings.

## Supabase / Google Console setup (operator action)
1. Create/configure Google OAuth client (Android package + SHA fingerprints; web client where applicable).
2. Add Google provider client ID/secret in Supabase Auth provider settings.
3. Configure allowed redirect URLs for local development, Android deep link and web/PWA production domains.
4. Register the app callback scheme/intent filters and verify Android App Links/deep links.
5. Never commit client secret, service-role key or OAuth secret to repository/mobile bundle.
6. Configure production domains only after owner approval; deployment is not performed by this checklist.

## Acceptance tests
- New Google identity creates exactly one auth user/profile.
- Existing identity logs in to same account.
- OAuth cancellation returns safely without duplicate account.
- Invalid/missing callback and provider outage show recoverable errors.
- Session persists/revokes correctly; unauthenticated deep links redirect to login.
- No email/password controls or password auth calls remain in app.
- JWT subject is the identity used for RLS/API authorization.
- Android physical device and web callback tests pass.

## Current truth
Google-only auth: specified, NOT implemented/verified.
Supabase/Google console configuration: not inspected or changed.
Android callback/device tests: not run.
