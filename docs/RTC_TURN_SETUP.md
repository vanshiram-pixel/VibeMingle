# TURN relay setup for VibeMingle

The `rtc-ice-servers` Edge Function returns authenticated ICE configuration. It always provides the configured STUN URLs and adds TURN only when all TURN secrets are present.

## Required TURN provider settings

Use a Coturn-compatible TURN service with REST-style shared-secret authentication. Configure these Supabase Edge Function secrets:

- `RTC_TURN_URLS`: comma-separated TURN endpoints, including transport where required, for example `turn:turn.example.com:3478?transport=udp,turns:turn.example.com:5349?transport=tcp`.
- `RTC_TURN_SHARED_SECRET`: the provider's REST authentication shared secret. Keep it only in Supabase Edge Function secrets; never put it in Flutter/Dart defines, web environment variables, source control, or the app binary.
- `RTC_STUN_URLS` (optional): comma-separated STUN endpoints. Defaults to Google's public STUN endpoint.

The function creates a username in the form `expiry-unix-timestamp:user-uuid` and an HMAC-SHA1 Base64 credential with a one-hour lifetime. The TURN provider must be configured with the matching shared secret and REST authentication mode.

## Deploy after provider provisioning

After a TURN provider has been selected and its credentials have been provisioned, set the secrets and deploy the function:

```sh
supabase secrets set RTC_TURN_URLS="turn:turn.example.com:3478?transport=udp,turns:turn.example.com:5349?transport=tcp"
supabase secrets set RTC_TURN_SHARED_SECRET="REPLACE_WITH_PROVIDER_SHARED_SECRET"
supabase functions deploy rtc-ice-servers
```

Do not use the example hostname or placeholder secret. Validate UDP and TCP/TLS reachability, expiry behavior, and two-device calls on separate mobile networks before production launch.

## Current behavior

Without TURN secrets, the function returns STUN-only configuration so development calls can still attempt direct connectivity. The web and Android clients call this function and retain their STUN fallback if it is unavailable. This repository change does not deploy the function or configure a provider.
