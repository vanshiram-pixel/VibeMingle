# VibeMingle — Final Scope Lock (V3 Complete Product)

**Status:** Scope decisions locked; implementation has not started.  
**Product:** VibeMingle — *Connect Beyond Borders*  
**Repository:** vanshiram-pixel/VibeMingle  
**Branch:** docs/final-scope-lock-v3  
**Purpose:** Record all product and engineering decisions agreed so far. This is a scope/requirements lock, not proof of implemented or tested functionality.

## 1. Product Direction (LOCKED)

- Build **VibeMingle V3 as the complete final product**, not a limited MVP.
- V3 includes the approved V1 foundation/core and V2 advanced capabilities; there will be no intentionally incomplete V1/V2 product that omits the agreed core.
- Work may be delivered internally in controlled implementation stages, but stages do not reduce the final locked scope.
- Target surfaces: Android app, public website, and a complete web Admin Panel.
- Primary product: global random social/video chat with supporting social, safety, monetization, and community capabilities.
- Brand: **VibeMingle**. Tagline: **Connect Beyond Borders**.
- First development target: **Local Development**; then Dev/Staging; then Production.

## 2. Technology Direction (LOCKED AS THE CURRENT BASELINE)

- Android client: Flutter.
- Public web: Next.js + TypeScript.
- Admin Panel: Next.js + TypeScript, with role-separated access and protected administrative routes.
- Backend/data/auth baseline: Supabase (Auth, PostgreSQL, RLS, server-side functions/Edge Functions where appropriate).
- Real-time video/audio: LiveKit / WebRTC.
- Push notifications: Firebase Cloud Messaging (FCM).
- AI services: server-mediated OpenAI API integration; no provider secret in client apps.
- Monitoring/error reporting: Sentry or an approved equivalent.
- CI/CD and hosting: Vercel for web surfaces and approved deployment infrastructure for backend/media services.
- Payments: Google Play Billing for eligible Android digital goods/subscriptions; web payment provider only after legal, regional, tax, and platform-policy review.
- Ads: AdMob on Android and AdSense on eligible web surfaces, subject to policies and consent. No ads during active live calls.
- Exact provider plans, regions, quotas, costs, and production configuration remain implementation-time validation items; this baseline does not imply accounts/services are configured.

## 3. Authentication and Onboarding (LOCKED)

- Google is the sole login/signup provider.
- One **Continue with Google** action serves both first-time registration and returning login.
- No email/password login, phone OTP login, or Apple login in the current locked scope.
- Identity must be keyed to the stable Google provider subject (sub), not email alone. Email changes must not create duplicate identity or silently link accounts.
- First-time Google identity enters onboarding; returning identity enters the authenticated app.
- Onboarding includes age assurance/gate, username uniqueness, profile/avatar, country/language, preferences, and required Terms/Privacy/Community Rules consent.
- The exact legally compliant age-assurance method is a launch gate; a simple self-declaration is not assumed sufficient in every jurisdiction.

## 4. Core User Product (LOCKED)

- Home and random-match entry.
- Match queue and server-authoritative matchmaking.
- User preferences/filters within approved policy and product constraints.
- Live audio/video calling using LiveKit/WebRTC.
- Call controls, chat, connection status, call timer/status, and call ending.
- Normal skip is subject to a **15-second server-enforced lock**; UI-only enforcement is insufficient.
- Report, block, and emergency exit remain available at all times, including during any skip lock.
- Reconnect, network degradation, peer disconnect, timeout, match cancellation, and call failure recovery.
- User profiles, profile editing, privacy/settings, friends, friend requests, messaging/social inbox.
- Notifications, support/help, legal documents, safety settings, report history/appeals as permitted.
- Optional AI voice translation/subtitles with original audio fallback; feature off by default, consent-aware, cost-limited, and provider secrets server-side.
- No recording by default. Do not promise prevention of screenshots or external recording.

## 5. Safety, Moderation, and Privacy (LOCKED)

- Report/block and safety controls are core product functionality, not optional polish.
- Moderation workflows include report intake, evidence/metadata handling with minimization, triage, actions, appeal/review, audit trail, and escalation.
- Age/minor safety, sexual-content policy, harassment, exploitation, impersonation, spam, scams, and abuse controls must be designed before launch.
- Mutual consent is required for private audio/video invitations; invitation states include request, accept, reject, ignore/expiry, withdrawal, and rate limits.
- Consent does not override applicable law, platform policy, or safety restrictions.
- Data minimization, purpose limitation, retention/deletion rules, user privacy controls, and consent records must be specified.
- RLS and server authorization must protect every user-owned record; never trust client-supplied user IDs or role claims.
- Admin access requires RBAC, MFA/strong authentication, least privilege, and immutable/auditable sensitive actions.
- Security, privacy, moderation, and legal review are release gates.

## 6. Social, Economy, and Monetization (LOCKED)

- Social: friends, requests, messaging/inbox, profiles, presence where privacy settings permit.
- Economy: VIP/subscriptions, coins, gifts, referrals/rewards, transaction history, and a server-authoritative ledger.
- Wallet balance must never be trusted from the client. All credits/debits require idempotency, reconciliation, auditability, and anti-fraud controls.
- Payment webhook signature verification, replay protection, duplicate-event handling, refund/chargeback handling, and reconciliation are mandatory.
- Creator/host/community features are included in the V3 target only after platform, legal, payment, safety, and abuse constraints are specified and approved.
- Advertising must respect platform policies, privacy/consent, and placement rules; never interrupt an active live call.

## 7. Admin Panel (LOCKED)

The complete Admin Panel scope includes:
- Dashboard and operational health.
- User lookup/profile and account actions with permissions/audit.
- Reports, moderation queue, enforcement, appeals, escalation.
- Safety policies and moderation configuration.
- Payments, subscriptions, coins, wallet ledger, refunds/reconciliation views (restricted roles).
- Ads/placements and campaign configuration where permitted.
- CMS: legal pages, help/support, announcements, localization/content.
- Feature flags, rollout controls, kill switches.
- Analytics, product metrics, abuse/fraud indicators.
- Admin users, roles, MFA/security controls, audit logs.
- System settings, integration status, incident/maintenance controls.
- Sensitive actions must require appropriate authorization and produce audit records.

## 8. V2 and V3 Capability Inclusion (LOCKED)

**V2 capability set included in final V3:** smarter preference/matching, advanced AI translation, richer social/community features, monetization/economy, referral/rewards/achievements, advanced moderation workflows, analytics/retention, admin automation, quality/performance improvements.

**V3 capability set:** global/multi-region readiness, privacy-aware personalization, extensible community/creator ecosystem, mature trust/safety, mature economy, advanced AI controls, availability/disaster recovery, localization, observability, and extensible partner/API architecture.

These are requirements to specify and validate—not claims that they are already built or that every provider supports every feature without additional configuration.

## 9. Required Specification Depth (LOCKED)

Every screen, module, and feature must be documented with:
1. Purpose, user/role, entry/exit/navigation.
2. UI layout and all visible elements.
3. Every button/action, preconditions, result, loading/disabled/error states.
4. State machine and business rules.
5. API contract (auth, request, response, errors, idempotency).
6. Database entities, relations, constraints, indexes, retention.
7. Authorization/RLS and abuse/rate-limit rules.
8. Dependencies and cross-module wiring.
9. Offline/network/time-out/retry/recovery behavior.
10. Accessibility, localization, analytics events where appropriate.
11. Unit/integration/e2e/security tests and acceptance criteria.
12. Operational monitoring, alerts, rollback/kill-switch where relevant.

No feature is considered complete merely because a screen or button exists.

## 10. Mandatory Modules/Engines (LOCKED)

- Identity/Auth & Session.
- Onboarding/Profile.
- Matchmaking/Queue.
- Live Call/LiveKit.
- Chat/Messaging.
- Consent/Private Call.
- Translation/AI.
- Trust, Safety & Moderation.
- Friends/Social/Presence.
- Notification.
- Economy/Wallet/Ledger.
- Subscription/Payments.
- Ads/Consent.
- Support/CMS/Legal.
- Admin/RBAC/Audit.
- Analytics/Telemetry.
- Feature Flags/Configuration.
- Security/Privacy/Data Lifecycle.
- Deployment/Monitoring/Backup/Disaster Recovery.

## 11. Required Quality and Release Gates (LOCKED)

- No secrets in Git, client bundles, logs, or public repository.
- Environment separation: local, dev, staging, production.
- Database migrations are versioned, reviewed, and reversible where practical.
- Automated tests: unit, integration, API contract, end-to-end, authorization/RLS, payment/webhook, moderation, and failure/recovery.
- Security checks: dependency scanning, secret scanning, static analysis, abuse/rate-limit checks, admin authorization tests.
- Load/latency/quality tests for matching and live-call flows.
- Monitoring, alerting, incident runbooks, backups, restore tests, and rollback plans.
- Launch blocked by unresolved critical/high security issues, broken safety flows, unverified payment ledger, or untested data recovery.
- A feature lifecycle must be tracked explicitly: **SPECIFIED → APPROVED → IMPLEMENTED → WIRED → TESTED → VERIFIED**.
- A status may only be marked when evidence exists; documentation is not implementation evidence.

## 12. Scope Change Rule (LOCKED)

- This document records decisions agreed so far.
- New features, removals, or changed behavior require a visible change request, impact analysis (UI/API/database/security/cost/testing), and explicit approval before modifying the locked scope.
- If a later decision conflicts with this lock, the newer explicit user-approved decision supersedes the affected section only; unaffected scope remains locked.
- “Final scope locked” means requirements are frozen for planning/specification—not that code, integrations, tests, or production deployment are complete.

## 13. Current Repository Truth (AS OF LOCK)

- Repository exists: https://github.com/vanshiram-pixel/VibeMingle
- Initial state inspected: starter repository with README and `.gitignore`.
- This document is a requirements baseline; no implementation, integration, audit pass, or production readiness is implied.
- Next engineering artifact: exhaustive page-by-page specification, screen/button/function map, API contracts, schema/RLS, integration matrix, and acceptance/security test catalog.
