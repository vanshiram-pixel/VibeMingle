# VibeMingle — Master Roadmap & Scope Control (v1.1)
Updated: 2026-11-15
Branch audited: feat/typing-presence
Repository: vanshiram-pixel/VibeMingle

## Canonical scope — V4.1 HARD LOCK
**V4.1 is the sole approved implementation target.** Scope is hard-locked by [V4.1 Final Hard Lock & Implementation Roadmap](./V4_1_FINAL_HARD_LOCK_AND_IMPLEMENTATION_ROADMAP.md). No new product features beyond V4.1 may be added. All V1/V2/V3/V4 decisions and post-V4 reviews are preserved and consolidated into V4.1.

Read the V4.1 lock together with:
- [V4 final hard locks](./V4_FINAL_HARD_LOCKS.md)
- [Final master product blueprint](./FINAL_MASTER_PRODUCT_BLUEPRINT.md)
- [Updated screen-by-screen/button blueprint](./V4_FINAL_UPDATED_SCREEN_BY_SCREEN_BUTTON_BLUEPRINT.md)
- [Advanced translation/chat/security](./V4_ADVANCED_ADDONS_TRANSLATION_CHAT_SECURITY.md)
- [25-phase development plan](./V4_25_PHASE_FINAL_DEVELOPMENT_MASTER_PLAN.md)
- [V1–V4 repository reconciliation audit](./V1_V2_V3_V4_RECONCILIATION_AND_REPOSITORY_AUDIT.md)
- [Instant stranger matching](./instant-stranger-matching.md)
- [Unified connections/social system](./CONNECTIONS_UNIFIED_SOCIAL_V4.md)
- [Stranger match/friend flow](./STRANGER_MATCH_FRIEND_FLOW.md)

## Product scope
Android + Website/PWA + Admin/Ops; Google-only auth; age/consent/account lifecycle; profile/media; unified social connections; discovery/presence; instant and manual stranger matching; stranger video; private audio/video calls; advanced E2EE chat; cross-call voice translation; notifications; privacy/safety/report/block/appeals; scoped evidence vault; admin RBAC/audit/monitoring/flags/rollout/rollback; wallet/VIP/coins/gifts/payments; rewards/referrals; CMS/campaigns; support; reliability, accessibility, security, compliance and launch operations.

## Scope invariants
- Friend is mutual; Follow is one-way and does not grant chat/call rights.
- Canonical chat is reused; no duplicate thread.
- Private calls require request + recipient acceptance.
- Block overrides every social/chat/call/match path.
- Server-authoritative pairing, authorization, consent, payments, safety actions; idempotency and one-active-session.
- Next 15-second cooldown; safety exits immediate; matching latency figures are conditional targets only.
- No silent filter broadening.
- No covert recording/camera/mic, universal plaintext access or E2EE backdoor.
- Only scoped, authorized report evidence can be exported, encrypted, audited and retention-limited.
- Approximate IP geolocation only; GPS is consented and not visible to strangers.
- AI safety is contextual, with human review/appeal; no keyword-only automatic punishment.
- Per owner scope instruction, sexual exploitation/grooming indicators are excluded from general AI monitoring/detection/alerts; other safety categories remain.
- Admin emergency controls cannot disable auth, encryption, consent, report/block or immediate safety exits.
- Security is layered; no promise of zero bugs/hacks.

## Repository evidence (last audit: 2026-11-15)
- Flutter mobile shell, GoRouter, Supabase auth/session UI; Google-only OAuth not verified.
- Friends screen/repository and migrations.
- Chat migration/repositories/basic thread UI; runtime not tested.
- Presence migration/repository.
- Call session migration/repository, incoming-call UI and WebRTC controller scaffold.
- Notification/preferences migration; profiles migration/trigger.
- No web app/admin app, AI, payments/coins/gifts, ads, production CI or release artifacts evidenced.
- Supabase migrations not proven applied; Flutter compile and two-user/device E2E not proven.
- PR #1 remains draft/unmerged.
- No live Supabase, Android device, browser, production test or external provider is asserted unless evidence is recorded.

## 25-phase execution order (V4.1)
P01 Repository Audit & Baseline  
P02 Architecture & Contracts  
P03 CI/Environments/Dev Foundation  
P04 Google Auth & Account Lifecycle  
P05 Onboarding/Age Eligibility/Consent  
P06 Profile/Media/Identity  
P07 Privacy/Safety/Blocking  
P08 Connections Social System  
P09 Discovery/Presence  
P10 Canonical Chat/Messaging  
P11 Notifications/Deep Links  
P12 Matchmaking Engine/Queue  
P13 Stranger Video Session  
P14 Private Audio/Video Calls  
P15 Moderation/Admin/Ops  
P16 Website/PWA Core Parity  
P17 AI/Translation  
P18 VIP/Coins/Gifts/Payments  
P19 Rewards/Referrals/Engagement  
P20 CMS/Campaigns/Analytics  
P21 Scale/Reliability/Performance  
P22 Full QA/Security/Compliance  
P23 Closed Beta  
P24 Production Release/Launch (owner approval required)  
P25 Post-launch Operations

## Implementation truth labels
SPECIFIED → IN_PROGRESS → IMPLEMENTED → INTEGRATED → VERIFIED → RELEASED.
Documentation/schema/UI alone is not completion. Each button/function must have route, preconditions/states, handler, API contract, backend authorization/logic, DB transaction/index/constraint, realtime event, success/error/retry behavior, privacy/security, admin visibility, and tests/evidence.

## Current status
V4.1 product scope is **HARD-LOCKED**. Software implementation remains partial. Do not claim a phase is complete without code, integration, tests and evidence. Next work: repository audit and traceability matrix → exact API/DB/event contracts → implementation in dependency order → CI and test evidence → staging/beta → deployment readiness.

## Release gates
Scope → code → integration → quality → security/privacy → operations/rollback → closed beta → owner-approved launch. Notify user and obtain explicit approval before production deployment, public launch, store release or PR merge.

## Scope change control
No V4.1 feature expansion. Engineering fixes, integration and security corrections that preserve locked scope are allowed. Any new feature requires separate future-version approval; never silently add it.

**Final:** V4.1 is the fixed target. Build, integrate, verify and prepare launch against this scope only.