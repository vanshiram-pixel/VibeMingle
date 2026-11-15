# Typing Indicator & Presence — Implementation Contract

Branch: `feat/typing-presence`
Scope: VibeMingle private 1:1 conversations; no public typing broadcast.

## 1. Typing indicator (ephemeral; no database writes)
- Use Supabase Realtime Broadcast on a channel scoped to the conversation: `typing:<conversation_id>`.
- Subscribe only after the current user is authorized as a conversation member (membership/RLS remains the source of truth).
- Broadcast payload: `{ user_id, typing: true|false, sent_at }`; never include message text, phone/email, or profile secrets.
- Send `typing=true` on first keystroke; throttle subsequent events to at most one every 1–2 seconds.
- Send `typing=false` after 1.2 seconds of inactivity, on send, on focus loss, and on dispose.
- Receiver ignores own user_id and expires remote typing state after 3 seconds (failsafe for disconnects).
- UI: small animated three-dot indicator + “Friend is typing…” below messages; reserve no large layout space.
- Broadcast is best-effort: chat sending must never depend on typing events.

## 2. Online / last-seen presence
- Separate Supabase Realtime Presence channel per authenticated user (private user channel).
- Track only minimal state: `user_id`, `online`, `last_seen_at`; do not track device IDs or location.
- Online status is visible only to accepted friends / existing conversation participants, enforced server-side.
- App lifecycle: mark online on authenticated foreground; mark offline and update last_seen on background/disconnect. Treat abrupt disconnects as eventually offline (presence sync/TTL).
- Display “Online” or a human-readable “last seen …” only where privacy settings permit; unknown/offline state must not be presented as exact.

## 3. Flutter wiring checklist
- Add a dedicated `TypingPresenceController` (or equivalent) to keep channel lifecycle out of widget build.
- Bind TextField `onChanged` to typing controller; keep current send/edit/delete/report flows unchanged.
- Subscribe/unsubscribe channels safely; cancel timers and dispose controllers.
- Guard callbacks with `mounted` and current conversation ID; handle reconnects without duplicate subscriptions.
- Add tests for debounce, timeout, self-event filtering, conversation isolation, and disconnect cleanup.

## 4. Security & acceptance gates
- Verify membership before opening conversation-scoped channels; configure Realtime authorization/RLS.
- Never persist every keystroke to `messages` or a typing table.
- A non-member cannot subscribe to or broadcast into another conversation.
- Typing state clears within 3 seconds after sender stops/disconnects.
- Existing chat works when Realtime is unavailable; no crash or send blockage.
- Do not claim online state unless presence is confirmed.

## 5. Completion status
- [ ] Flutter typing controller + UI
- [ ] Conversation channel authorization
- [ ] Presence lifecycle and privacy gate
- [ ] Unit/widget tests
- [ ] Integration test with two authenticated users
- [ ] CI/build verification
