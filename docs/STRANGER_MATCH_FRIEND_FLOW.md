# VibeMingle — Stranger Match → Friend → Chat/Private Call Contract
Updated: 2026-11-15
Status: **LOCKED PRODUCT LOGIC / NOT YET IMPLEMENTED OR RUNTIME VERIFIED**
Branch: feat/typing-presence

This document is the permanent product contract for making friends from a Stranger Match. It is additive to the master blueprint and matching specification.

## 1. Match screen actions
During an active Stranger Match, show contextual actions:
- **Add Friend** (send mutual friend request)
- **Follow** (one-way relationship)
- **Chat** (message within the current match conversation, subject to session rules)
- **End**, **Next**, **Report**, **Block** (safety exits always available)
- Mic/camera/audio controls

Do not imply that Follow or Add Friend automatically grants private-call permission.

## 2. Add Friend flow
1. User A taps Add Friend on the active match card or match participant profile.
2. Backend validates both accounts are eligible, distinct, not blocked in either direction, not suspended, and no existing accepted friendship.
3. Create one idempotent pending friend request A→B; reject duplicate requests/rate abuse.
4. UI changes to **Request Sent** / **Requested**; allow Cancel Request if still pending.
5. B receives in-app/push notification and Incoming Friend Request entry with **Accept** and **Decline**.
6. Accept is server-authoritative and atomic: create mutual friendship, resolve request, emit events to both users; idempotent if repeated.
7. Decline resolves the request without creating friendship; enforce configurable re-request cooldown/rate limit.
8. If a reciprocal pending request already exists (B→A), accept/resolve both and create friendship atomically rather than duplicate records.
9. Both users appear in each other's Friends list. The existing match conversation remains the same conversation; do not create a duplicate thread.
10. Friend status is not a call connection: a private call still requires a separate call request and receiver Accept.

## 3. Follow flow (independent)
- Follow is one-way and can be toggled independently of friendship.
- Follow does not create a conversation, friendship, or call permission.
- If a block is created, remove/disable follow edges both directions as product policy and prevent re-follow until unblock.
- Match screen and profile can both expose Follow/Following/Unfollow; actions are idempotent.

## 4. Post-match
After End/peer leave/session closure, show Post-Match actions:
- Add Friend / Request Sent / Friends (relationship-aware)
- Follow / Following
- Continue Chat (only if messaging policy allows)
- Next Match / Return Home
- Report / Block
The post-match screen must not reopen or reconnect the ended media session. Friend request may be sent from the match record while it is still authorized and visible to the participant.

## 5. Chat and history
- A match creates/uses the canonical conversation associated with the two participants/session; no second chat identity.
- If they later become friends, reuse the same canonical one-to-one conversation, not a duplicate conversation.
- Match system events/call metadata may be shown in history; private messages continue only under messaging policy.
- Chat-list visibility follows conversation/message rules, not Follow or Friend Request alone. A friendship alone may not create an empty chat row unless product chooses an explicit “Friends inbox” section.
- Block prevents new messages and calls and may terminate an active session; history retention/deletion is governed separately.

## 6. Private call eligibility after Match
- During an active match, the match call is automatic (no second Accept), as specified by matching contract.
- After match ends, the old session cannot be rejoined or used as a repeat call.
- A non-friend former match cannot direct-call/reconnect. They may meet again only through a new eligible Stranger Match; pairing cooldown/block rules apply.
- After friendship is accepted, either friend can initiate a private audio/video **Call Request** if recipient privacy permits.
- Receiver sees Incoming Call with Accept/Decline; media connects only after Accept.
- Friendship is eligibility, not consent to ring/connect. Call privacy (“Friends” or “Nobody”), availability/busy state, blocks, account status, rate limits and call request limits are checked server-side.
- Follow, pending request, chat existence or previous match alone never grants private call permission.
- Block overrides friendship, follow, chat, match, and call relationships in all paths.

## 7. Relationship state labels (UI derives from server state)
| State | Match/Profile button | Request inbox |
|---|---|---|
| No relation | Add Friend | — |
| A sent request | Requested / Cancel Request | B: Accept / Decline |
| B sent request to A | Accept / Decline | A: Accept / Decline |
| Mutual friendship | Friends / Remove Friend | — |
| Blocked | Blocked / Unblock (own block list only) | No request/call/message/match |
| Follow only | Add Friend + Following | — |
| Friend + Following | Friends + Following | — |

## 8. Required backend operations/events (contract; names provisional)
- send_friend_request(target_user_id, idempotency_key)
- cancel_friend_request(request_id)
- accept_friend_request(request_id)
- decline_friend_request(request_id)
- follow_user(target_user_id) / unfollow_user(target_user_id)
- remove_friend(target_user_id)
- block_user(target_user_id) / unblock_user(target_user_id)
- friend_request.created / accepted / declined / cancelled
- friendship.created / removed
- follow.created / removed
- match.ended / post_match.available
All operations: authenticated actor, server authorization, block checks in both directions, validation, rate limit, idempotency, transaction/race handling, RLS and audit/analytics as appropriate. Treat names as contract placeholders until implementation is committed.

## 9. Acceptance tests (minimum)
1. Match A/B; A sends request → B sees it; Accept → both Friends.
2. Same action twice does not duplicate request/friendship/notification.
3. Reciprocal pending requests resolve into one friendship.
4. Decline creates no friendship; cooldown applies.
5. Follow does not create friend, chat or call permission.
6. Friend does not auto-connect a call; receiver Accept is required.
7. Former match without friendship cannot private-call or rejoin old session.
8. Friend can call only if privacy allows; blocked/busy/offline/rate-limit outcomes are explicit.
9. Block during match terminates/invalidates contact and excludes future pairing; all message/call/request endpoints reject.
10. Match conversation remains canonical after friendship; no duplicate thread.
11. Cancel/decline/remove/unfollow update both client states through realtime and refresh.
12. Report/End/Block remain immediately available regardless Next cooldown.

## 10. Status
**Specified and locked; implementation NOT STARTED/NOT VERIFIED as a complete vertical slice.** UI, API/RPC, database constraints, RLS, notifications, race tests and two-user runtime tests are still required.
