# VibeMingle Android (Flutter)
Flutter workspace target for VibeMingle.

## Dependencies
- Supabase Flutter Auth
- LiveKit Flutter SDK (`livekit_client`)
- HTTP client for authenticated Fastify API requests

## Local setup
Run from `apps/mobile` with Flutter stable and Dart 3.10+:
```sh
flutter pub get
flutter analyze
flutter test
```

Build-time configuration (never commit real secrets):
```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
  --dart-define=API_BASE_URL=https://YOUR_API_HOST
```
- `SUPABASE_URL` and anon key configure Supabase Auth.
- `API_BASE_URL` is the Fastify API origin (no `/v1` suffix).
- Onboarding sends the current Supabase access token as a Bearer token to `POST /v1/onboarding/complete`.
- Configure Google OAuth redirect `com.vibemingle://login-callback/` in Supabase and Android intent filters before testing sign-in.

The repository currently contains UI scaffolds and SDK dependency only. Generated Android/iOS platform projects, secure API token fetching, room connect, camera/mic tracks, participant rendering, and end-to-end call tests must still be implemented and verified. Do not place LiveKit API secrets in the mobile app.

**Safety note:** profile creation alone does not grant call/matching eligibility. The consent-history and jurisdiction-appropriate age-assurance service must be implemented and verified server-side before enabling those features.
