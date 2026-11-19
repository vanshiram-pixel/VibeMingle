# Chat realtime and notifications

## ChatRepository
- `conversationKey(a,b)` produces a stable pair key.
- `loadMessages` paginates by timestamp, capped at 100.
- `send`, `edit`, `delete`, `markDelivered`, `markRead` call server RPCs.
- `subscribe` listens to inserted messages for one conversation; configure private channel authorization and verify RLS in staging.

## Notification schema
Migration `0005_notification_preferences.sql` adds user preferences, inbox and mark-read RPC.
Client cannot insert notification rows. Trusted server/Edge Functions should create inbox notifications and dispatch push messages after verifying call/message/request events.

## Push architecture
1. Flutter registers FCM/APNs token with authenticated Edge Function; tokens stored per device and revoked on logout.
2. Server emits notification only after committed event and preference/quiet-hours checks.
3. Incoming call push should contain opaque call ID + caller display-safe ID only; never SDP/ICE.
4. App opens authenticated call fetch, checks state/participant/block status, then renders incoming call.
5. On accept/decline, server transition wins; push delivery is not authoritative.
6. Handle token rotation, duplicate delivery, expired call, notification permissions denied and app terminated/background.
7. Add rate limiting, generic lock-screen text option, token encryption/retention and privacy policy.

No FCM/APNs credentials or Edge Functions are configured by this repository commit.
