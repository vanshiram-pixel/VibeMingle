# VibeMingle Connections — Unified Social System (V4)

**Status:** Product contract locked; code integration pending verification.

## One entry point
The app and web expose one navigation category: **Connections**. Do not ship separate Fans, Followers, Follow, Friends or Friend Management menu systems.

Tabs:
- **Friends:** accepted mutual relationships.
- **Requests:** received + sent friend requests (Accept, Decline, Cancel).
- **Followers:** people who follow the current user. “Fans” is a legacy synonym and maps to this same list/count.
- **Following:** accounts the current user follows.
- **Discover People:** searchable/suggested people and online profiles.

## Relationship semantics (must not be conflated)
- Follow = directional `follower_id → followed_id`; unfollow removes that edge.
- Friendship = mutual accepted relationship; represented by a canonical pair or symmetric membership.
- A friend may also follow another user; UI must not show duplicate relationship cards or duplicate counts. The friendship state and follow state may coexist but are rendered as one profile relationship summary with clear actions.
- A pending friend request is not friendship and does not create a chat.
- Follow alone does not grant private chat, call or match eligibility.
- Friends may be eligible for private call/chat subject to separate privacy settings, block and availability checks.

## Profile action precedence
1. Blocked relationship: show Unblock (where permitted); hide/disable social, chat, call and match actions.
2. Friends: Friends status + Remove Friend; Follow/Unfollow remains independent if product allows.
3. Incoming request: Accept / Decline.
4. Outgoing pending request: Requested / Cancel Request.
5. Otherwise: Add Friend and Follow/Unfollow as separate explicit actions.
6. Message and Video Call are separate gated actions; no implicit chat/call on Follow/Friend.

## Canonical data/API ownership
- Keep distinct underlying entities/constraints for `friend_requests`, `friendships`, `follows`, and `user_blocks`; do not merge different relationship semantics into one boolean.
- One shared Connections repository/service and one notification/event family should coordinate actions and refresh all tabs/profile counters.
- Use unique constraints, authenticated actor checks, idempotency, rate limits, server-side block checks and RLS.
- Followers count = unique active incoming follows; Following count = unique active outgoing follows; Friends count = accepted mutual pairs. Fans count is an alias, never separately stored.
- Request accept must be atomic/idempotent; reciprocal requests resolve safely to one friendship. Block policy must clean/disable relevant edges and prevent new requests/actions.

## UI and states
Each tab has loading, empty, error/retry, offline and pagination states. Profile cards have one canonical relationship badge/state and no duplicate Fan/Follow controls. Notifications deep-link into the relevant Connections tab/action. Counts are server-derived and reconcile after mutation.

## Acceptance tests
- Follow/unfollow affects Followers and Following exactly once.
- Fans alias displays identical Followers data/count; no second endpoint/table/count.
- Request sent/accepted/declined/cancelled transitions correctly; duplicate taps/retries are idempotent.
- Mutual request race yields one friendship.
- Follow does not create chat or allow private call.
- Block prevents follow/request/chat/call/match and removes/locks relationship surfaces per policy.
- Profile, Discover, Match, Chat and Connections all refresh from shared service state.
- RLS denies cross-user mutation/read; UI state reconciles after errors.
