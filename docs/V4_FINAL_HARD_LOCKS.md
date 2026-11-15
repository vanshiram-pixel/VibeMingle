# VibeMingle Version 4 — Final Hard Locks & Unified Master Specification

**Status:** PRODUCT SCOPE LOCKED; implementation and verification tracked separately  
**Date:** 2026-11-15  
**Branch:** `feat/typing-presence`

## 1. Version policy
V4 is the consolidated master specification, not a destructive replacement of V1/V2/V3 and not a claim that all features are already implemented. V1, V2 and V3 remain intact as delivery/expansion layers. V4 unifies their contracts, removes duplicate product surfaces, clarifies ownership, and defines acceptance/release gates. Any change to a hard lock requires an explicit user decision and an updated spec/roadmap.

- **V1 — Core:** Google auth, onboarding/profile, discovery/social, matching, chat, private audio/video calls, presence, notifications, safety, Android/web foundation.
- **V2 — Advanced:** AI/translation, richer social/engagement, VIP/subscriptions, coins/gifts/rewards, ads, campaigns and analytics.
- **V3 — Scale:** global readiness, personalization/recommendations, creator ecosystem, advanced trust/safety, scalable infrastructure and integrations.
- **V4 — Unified final:** all V1–V3 scope consolidated into one architecture, one navigation taxonomy, shared backend contracts, full integrations, testable acceptance criteria and controlled release.

## 2. Hard locks (authoritative)
1. **Authentication:** exactly one “Continue with Google” entry; first sign-in provisions account/onboarding, returning user signs in. No password or alternate OAuth login.
2. **Surfaces:** Android app + responsive website/PWA + Admin/Ops console; shared domain rules and API contracts.
3. **No fake functionality:** no mock match, fake online status, false call-connected state, fake payment success or placeholder button presented as complete.
4. **Matching modes (distinct user choices, shared engine):**
   - Instant Random: start → eligible queue → server pairs → automatic video session.
   - Random Switch/Next: Next after 15-second minimum; target 1–2 seconds if a compatible waiting peer exists; no guaranteed latency claim.
   - Manual Stranger Search: user selects supported gender preference, adult age range, language and optional other safe filters; server enforces eligibility and compatibility. No silent fallback that violates filters; show searching/no-match and allow cancel/change filters.
   - All modes use one authoritative matchmaking engine, queue, session model, safety checks and telemetry.
5. **Age & eligibility:** stranger video matching is adult-only (18+); age eligibility must be reliably verified according to product/legal policy, not trusted from a client-entered birth date alone. Do not expose exact DOB publicly.
6. **Video:** match auto-connect is distinct from private calls. Profile intro video/card preview is never a live call. A profile Video Call action sends a call request; recipient explicitly Accepts before connection.
7. **Match safety:** End, Report, Block, mute and camera-off are always immediately accessible. Next cooldown is not forced participation. Block excludes future match/calls/messages and resolves active relationship/session per policy.
8. **Social taxonomy — one UI category:** **Connections** is the sole social hub: Friends, Requests, Followers, Following, Discover People. Fans is an alias/duplicate of Followers and is removed as a separate surface/count system. Follow is one-way; Friend is mutual. Keep distinct relationship semantics and tables/permissions internally; one shared social API/event/notification framework where appropriate.
9. **Canonical conversation:** one conversation per user pair/session policy; match conversation is reused after friendship/private chat. No duplicate threads from match-to-friend transition.
10. **Private call consent:** friend eligibility alone never starts a call. Privacy/availability/block checks → incoming call request → explicit accept → WebRTC session.
11. **Privacy & safety:** privacy settings, block/report, moderation queues, consent, retention disclosures, rate limits and audit controls are mandatory—not optional post-launch decorations.
12. **Money integrity:** server-authoritative balances, idempotent ledger, verified payment webhooks, refund/reversal path; never trust client amounts or success callbacks.
13. **Shared UI state:** all screens/actions have loading, empty, error, offline, permission-denied and success states; no duplicate actions or conflicting signals.
14. **Accessibility/localization:** responsive layouts, keyboard/insets, screen-reader labels, clear permissions, Hindi/English foundation and RTL-safe components.
15. **Release gate:** production deployment/store launch only after explicit user notification/approval; CI, security, privacy, performance, QA and rollback evidence required.

## 3. Unified navigation
- **Home:** start matching, filter shortcut, discover suggestions, online people, recent conversations, requests/notifications.
- **Match:** Instant Random, Next/Random Switch, Manual Search; preferences and live queue status; in-session video/chat/safety controls.
- **Connections:** Friends, Requests (received/sent), Followers, Following, Discover People; no separate Fans menu.
- **Chats:** canonical conversations, unread/search/archive; match and private messages share authorized thread.
- **Calls:** incoming/outgoing/history and privacy controls; call request/accept flow.
- **Profile:** profile/media/intro video, follow/friend/message/call actions subject to permissions, privacy, wallet/engagement.
- **Activity:** notifications and actionable requests.
- **Safety & Settings:** privacy, block list, report/help, account and consent controls.
- **Admin/Ops:** RBAC dashboard, user lifecycle, moderation, matching/media health, CMS, feature flags, monetization, campaigns, analytics, support and audit; restricted access to private content.

## 4. Engineering rules
- Server-authoritative state, authorization on every endpoint, Supabase RLS where applicable, idempotency for mutations, rate limits/abuse prevention, structured errors, observability and audit events.
- Match pairing atomic; one active match/call policy per user; queue heartbeat/TTL; stale-event rejection; both-direction block checks; skip cooldown; fairness and filter compatibility.
- WebRTC signaling and TURN configuration are secrets-managed; permissions and device failure paths handled; call lifecycle has ringing/accept/reject/cancel/timeout/ended/failed.
- Database migrations are versioned, reviewed and tested; never label unapplied migrations “live”.
- Feature flags and phased rollout; rollback and incident procedures documented.
- Every feature must have: owner/surface, state machine, API/event, data/RLS, success/error/rollback, analytics, tests and acceptance criteria.

## 5. Definition of Done / status vocabulary
- **SPECIFIED:** contract documented.
- **IN_PROGRESS:** active code work.
- **IMPLEMENTED:** code exists.
- **INTEGRATED:** connected end-to-end across required surfaces/services.
- **VERIFIED:** tests/device/browser/backend evidence recorded.
- **RELEASED:** approved production rollout.
A scaffold, migration file, mock or docs alone is not IMPLEMENTED/VERIFIED.

## 6. Final acceptance gates
- Auth/onboarding/session recovery and account lifecycle verified.
- Social requests/friendship/follow/block consistency and deduplication verified.
- Instant, Next and manual matching tested under empty, busy, filter, block, reconnect and race conditions.
- Match video, private call request/accept, chat, translation consent and safety exits verified.
- Notifications deep-link to correct action; privacy preferences respected.
- Wallet/payment ledger, webhook replay, refund and fraud controls tested before monetization release.
- Admin RBAC, moderation/audit, privacy and access boundaries tested.
- Android + web responsive/accessibility, offline/error/permission states and cross-platform parity tested.
- CI, security review, load/latency, monitoring, backup/restore, rollback and launch checklist signed off.

## 7. Change control
This document is the Version 4 scope authority. Existing V1/V2/V3 docs remain historical/phase detail and must align with it. New decisions are appended here and reflected in blueprint, relevant feature specifications and roadmap. No silent scope deletion or duplicate product system.
