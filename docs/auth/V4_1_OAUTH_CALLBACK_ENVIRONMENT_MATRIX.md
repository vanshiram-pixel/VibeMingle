# V4.1 Google OAuth — callback and environment matrix

Status: SPECIFIED; external console and device validation pending.
No secrets or production settings are changed by this document.

## Current code
- Flutter entry point reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` using Dart compile-time environment.
- Google OAuth UI invokes Supabase `signInWithOAuth(OAuthProvider.google)`.
- OAuth success depends on Supabase provider configuration and a valid callback/redirect allow-list.

## Environment matrix
| Environment | Supabase URL/key | OAuth redirect | Required validation |
|---|---|---|---|
| Local Android | local/dev project | app custom scheme or verified app link | emulator + physical device |
| Web/PWA preview | dev project | exact preview origin callback | browser callback + refresh |
| Closed beta | staging project | beta app link/domain | two-account login/logout |
| Production | production project | production app link/domain | owner-approved release only |

## Setup runbook
1. In Google Cloud Console, create OAuth credentials appropriate to Android and web. Keep client secret server-side only.
2. In Supabase Auth > Providers > Google, enable Google and enter required client IDs/secret.
3. In Supabase Auth URL configuration, allow-list only exact development/staging/prod redirect URIs; avoid wildcard origins.
4. Configure Android package name, signing SHA-1/SHA-256 and intent/deep-link callback according to selected Supabase Flutter OAuth redirect strategy.
5. Configure web callback origin and HTTPS in preview/staging; production domain configuration waits for launch approval.
6. Run Flutter with environment values supplied securely (never commit real values):
   `flutter run --dart-define=SUPABASE_URL=<project-url> --dart-define=SUPABASE_ANON_KEY=<public-anon-key>`
7. Verify OAuth round trip returns to app/browser, session is present, Home updates, logout clears session and login again succeeds.
8. Confirm Supabase RLS uses authenticated JWT `auth.uid()`; never use client metadata as authorization.

## Security checklist
- Supabase anon/publishable key is public-client config; service-role key is never bundled.
- OAuth client secret is not in Dart, Android resources, Git, logs or APK.
- Redirect allow-list contains only trusted origins/schemes.
- Deep-link callback cannot accept arbitrary open redirect destinations.
- OAuth cancellation/error preserves logged-out state.
- New and existing Google accounts resolve to stable same identity.
- Auth session/token is not included in route parameters, analytics or logs.

## Current blockers / honest status
- Android project manifest/Gradle files were not found at the expected repository paths during source inspection; inspect actual tree before adding callback intent filters.
- Google Cloud/Supabase console settings are external and have not been changed or verified.
- No local Flutter SDK build, emulator or physical-device test is available in this GitHub-only workflow.
- OAuth callback: NOT VERIFIED. Production: untouched.
