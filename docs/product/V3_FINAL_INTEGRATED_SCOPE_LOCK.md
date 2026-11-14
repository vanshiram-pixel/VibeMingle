# VibeMingle — Integrated V1 + V2 + V3 Product Scope Lock
**Lock:** Product scope baseline **V3-FINAL-SCOPE-LOCK-01**  
**Repository:** vanshiram-pixel/VibeMingle  
**Branch:** spec/v3-integrated-master-draft  
**Status:** SCOPE LOCKED AS A BASELINE; implementation and verification are NOT complete.

## Product-owner instruction
VibeMingle is to be built as one complete integrated V3 product, incorporating V1 foundation, V2 advanced capabilities, and V3 global/platform capabilities. Do not deliver V1, V2 and V3 as disconnected products or omit V1/V2 features from the final product. Internal engineering milestones may be staged, but the approved target is the integrated V3 product.

## Canonical specification set (all must be read together)
1. `VibeMingle_Final_Master_Blueprint_v1.md` — product vision, platform, navigation, matching, video, translation, safety, monetization, admin, operations.
2. `VibeMingle_A_to_Z_Final_Master_Scope_Review_v1.md` — broad scope inventory and review.
3. `VibeMingle_Final_Scope_Lock_V1_V2_V3.md` — V1/V2/V3 scope baseline and integration.
4. `VibeMingle_V3_Red_Team_Audit_Final_Lock.md` — threats, attack paths, security controls and release gates.
5. `VibeMingle_V3_Advanced_RedTeam_Fixes_Integration_Final.md` — advanced fixes, secure contracts, integration and verification requirements.
6. `docs/product/V3_INTEGRATED_MASTER_SPEC_DRAFT.md` — consolidated product, pages, engines, data, APIs, integrations and acceptance gates.

These documents are cumulative. In case of conflict: (a) explicit product-owner decisions recorded in a dated decision log; (b) approved security/legal/platform constraints; (c) this integrated scope baseline; (d) supporting documents. Safety, privacy, law and platform policy always override a feature request.

## Locked product identity and core decisions
- Name: **VibeMingle**; tagline: **Connect Beyond Borders**.
- Global adult social/random video conversation platform; Android Flutter + Next.js web + complete Admin Console + backend/data/realtime/AI/economy/operations.
- Google-only sign-in; one Continue with Google for sign-up/login; provider stable subject is identity; no email-based account linking.
- 18+ policy and lawful age assurance; minors excluded. Age assurance method/jurisdictions remain implementation/legal decisions and must not be assumed solved by a simple checkbox.
- Server-authoritative random matchmaking, queue/reservation/room state, mutual compatibility and block exclusions.
- Ordinary Skip has a 15-second server-enforced lock; report, block and emergency exit are never locked.
- LiveKit/WebRTC video; no recording by default; consent is explicit and revocable for any separately approved capture/processing.
- Optional AI translation is off by default, consent/disclosure based, server-side, budget-limited and has original-audio fallback.
- Social graph, friend requests, messaging, private-call requests with mutual consent, notifications and support.
- VIP/subscription, coins, wallet ledger, gifts, referrals, rewards and purchase reconciliation are server-authoritative and fraud-resistant.
- Ad placements are policy/consent-compliant and never interrupt active live calls.
- Admin has least-privilege RBAC, MFA, sensitive-action approval and audit.
- V3 global architecture includes regional capacity/routing, localization, flags/rollouts, monitoring, resilience, backups, incident response and cost controls.

## Required integration—no feature islands
Auth ↔ onboarding/profile ↔ preferences/eligibility ↔ queue/match ↔ room/LiveKit ↔ call lifecycle ↔ chat/translation/safety ↔ call end/cleanup.
Social/friends/messages ↔ privacy/block ↔ notifications.
Reports/cases ↔ moderation/sanctions/appeals ↔ match eligibility.
Purchases/webhooks ↔ ledger ↔ entitlements/VIP ↔ UI/refunds/reconciliation.
Gifts/referrals/rewards ↔ ledger ↔ fraud controls ↔ notifications.
Ads ↔ consent/age/jurisdiction/entitlements ↔ placements.
Admin actions ↔ RBAC/MFA/reason/approval/audit.
Export/deletion/retention ↔ every data-owning module.
Feature flags ↔ client/server compatibility ↔ rollout/rollback.
Observability ↔ SLOs/alerts/incidents/runbooks.

## Mandatory completeness definition
A feature is complete only when all applicable items exist:
1. Requirement ID and product behavior.
2. Screen/page and every button/control/action.
3. State machine, validations, empty/loading/error/offline/retry states.
4. Function/handler and server-side behavior.
5. API/event contract and database schema/migration.
6. Authentication, authorization, RLS and privacy classification.
7. Abuse/rate-limit/idempotency controls.
8. Dependencies and cross-module wiring.
9. Unit/integration/E2E/security/accessibility tests.
10. Acceptance evidence, owner and lifecycle status.

## Final product scope—not a promise of current code
The scope includes all user app/web, admin, engines, APIs, data, integrations, safety/security, monetization, AI, operations and testing identified in the canonical documents. Any newly recovered historic V1/V2/V3 item is added through traceable scope reconciliation; omission is not accepted merely because it is absent from this summary.

## Open decision register
Age assurance and launch jurisdictions; exact gender preference interpretation; nearby/coarse-region behavior; skip-lock anchor/cooldown; call duration/device matrix; private-call access/pricing; chat encryption/retention; AI vendor/languages/processing/retention; coin/VIP/gift/refund/tax rules; ads consent and ad-free benefits; moderation staffing/SLA/evidence/appeals; launch languages/regions/data residency; SLO/RPO/RTO/capacity; analytics/consent; service boundaries/API deployment; legal entity, Terms, Privacy and child-safety procedures.
Open decisions must be closed or explicitly risk-accepted before their feature or production release. They do not authorize silently removing the feature.

## Implementation truth / release gate
At lock time, the GitHub repository was a starter shell (README and .gitignore); no product feature code was verified. Therefore:
- Scope: **LOCKED baseline**.
- Code: **NOT IMPLEMENTED**.
- Integration: **NOT WIRED/CONNECTED**.
- Tests: **NOT RUN/NOT VERIFIED**.
- Production: **NOT READY**.
- No claim of bug-free/100% secure is made.
- Release is NO-GO if critical/high security issues, cross-user authorization failures, auth/payment/ledger defects, unsafe age/moderation, broken account deletion, exposed secrets, or missing restore/rollback evidence remain.

## Change control
This is the integrated product scope baseline. Changes after lock require a change request with reason, affected requirements/screens/engines/data/API/security/tests/cost, compatibility and migration plan, and product-owner approval. Security/legal corrections may be mandatory and cannot be rejected to preserve a feature.

**Product scope lock acknowledged:** VibeMingle V1 + V2 + V3 are one integrated final-product target. This is a scope lock—not a code freeze, implementation completion, security certification or production approval.
