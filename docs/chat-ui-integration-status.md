# Chat screen integration notes

## Existing Flutter screen
`MessagingScreen` and `ConversationScreen` are now reachable from Home > Private Chats. The screen currently uses the older `conversations`, `conversation_members`, and `messages` schema/RPC names (for example `conversation_open`, `message_send`). The newer `0003_private_chat.sql` migration defines `chat_messages` and `chat_*` RPCs instead.

## Required reconciliation before runtime
- Choose one conversation schema and migrate screen/repository to it (recommended: chat_messages + stable pair conversation_id).
- Implement/confirm conversation list query without exposing non-participants.
- Configure Supabase Realtime authorization/private channels for typing and message events.
- Validate RLS and block-state behavior on every message operation.
- Test pagination, delivery/read receipts and edits/deletes with two authenticated users.
- Image uploads require a private Storage bucket, size/type validation and signed URLs.
