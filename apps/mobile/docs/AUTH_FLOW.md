# Mobile auth flow status
- Google OAuth uses Supabase PKCE and custom redirect `com.vibemingle://login-callback/`.
- Root app listens to Supabase auth state so login/logout changes update the visible route.
- A signed-in user currently enters onboarding each app start; server-backed profile completion routing is not yet implemented.
- Android intent filter/deep-link setup, Google OAuth redirect allow-list, and real device callback test remain mandatory.
- OAuth identity should remain Supabase's stable UUID; don't use email for account linking.
