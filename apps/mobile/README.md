# VibeMingle Mobile

Flutter Android client (V4.1 scope).

## Local setup
1. Install Flutter stable (Dart SDK included).
2. Configure Google OAuth in Supabase Auth and register the mobile redirect URI
   `io.supabase.vibemingle://login-callback/` in the provider/Supabase settings.
3. Configure the Android app intent filter for the same callback (platform project
   setup is still required).
4. Run from this directory:

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Never put a Supabase service-role key in a mobile app. Use only the public anon/publishable
key and enforce access with database RLS and server-side authorization.

## Current implementation boundary
The app shell and auth gate are scaffolded. Messaging UI currently calls the
`conversation_open`, `conversation_mark_read`, `message_send`, `message_edit`,
`message_delete`, and `message_report` RPCs; their SQL contracts/migrations and
security policies still need to be added and tested. This screen is not yet E2EE.
