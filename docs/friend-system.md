# Friends, requests and blocking

## Product flows
- Search/discover a profile -> send request -> recipient accepts/rejects.
- A reciprocal pending request is auto-accepted by `friend_request_send`.
- Friends list is a normalized pair row; remove friend deletes relationship.
- Block removes friendship, cancels pending requests and ends active calls.
- Unblock does not automatically restore friendship or old requests.

## API RPCs
- `friend_request_send(recipient_id)`
- `friend_request_respond(request_id, accept)`
- `friend_remove(friend_id)`
- `user_block(user_id)`
- `user_unblock(user_id)`

## Security and product requirements
- User identity is always `auth.uid()`; never accept a client-supplied sender ID.
- Requests/friend rows are visible only to their participants.
- Direct table writes are denied; mutations go through RPCs.
- Both-direction block checks are required before sending requests, starting calls, or delivering chat messages.
- Add profile visibility/search controls, request rate limits, spam reporting, notification preferences and abuse review.
- Do not expose email/phone or private profile fields through search results.
- Test concurrent reciprocal requests and duplicate sends; add uniqueness/idempotency constraints as needed.
- This SQL is a foundation and must be tested in staging before production.
