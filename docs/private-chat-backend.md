# Private chat backend

## Migration
Apply `supabase/migrations/0003_private_chat.sql` only in a staging Supabase project first.

## RPC contract
- `chat_send(recipient_id, body, conversation_id?)`: authenticated friend-only send, rejects blocks and oversized/empty text.
- `chat_mark_delivered(message_id)`: recipient-only delivery receipt.
- `chat_mark_read(message_id)`: recipient-only read receipt.
- `chat_edit(message_id, body)`: sender-only edit within 15 minutes.
- `chat_delete(message_id)`: sender-only soft delete.

## Client integration
1. Load recent messages by stable conversation key (participant pair); paginate older messages.
2. Subscribe to a private, server-authorized Realtime channel scoped to that conversation.
3. Send through RPC only; do not directly insert/update message rows.
4. Mark delivered on recipient device receipt; mark read when chat is foregrounded and message is visible.
5. Reconcile realtime events with fetched history using message UUID, avoid duplicate rendering.
6. Show sent/delivered/read timestamps; don't infer delivery from a local optimistic bubble.
7. Typing events remain ephemeral broadcasts and must not be persisted.

## Before production
- Add media attachment storage policies, upload size/type validation, malware scanning, report/moderation and retention controls.
- Add message pagination limits, rate limits, idempotency key, spam controls and privacy settings.
- Review conversation key semantics and migrate to a canonical conversation table if group chats or richer metadata are introduced.
- Verify all policies/RPCs with two users, blocked users, non-friends and expired sessions.
