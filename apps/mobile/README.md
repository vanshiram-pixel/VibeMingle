# VibeMingle Mobile

Initial Flutter app shell and dependency manifest.

## Prerequisites
- Flutter stable (Dart 3.3+)
- A Supabase project (credentials must never be committed)

## Run locally
```bash
cd apps/mobile
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

## Current status
- Material 3 app shell and GoRouter navigation: added
- Email/password screen layout: added (UI only)
- Supabase Auth: **not connected yet**
- Friends/chat/call screens: next integration step
- No real sign-in is performed by the current form. It intentionally displays setup-pending feedback.

Never place service-role keys in the mobile app. Use only the Supabase anon/publishable key and enforce authorization with RLS.
