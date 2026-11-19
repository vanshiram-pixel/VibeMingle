# VibeMingle V4.1 Advanced — Integration & Release Matrix

This is a full-product release track, not an MVP scope. A row marked scaffold/blocked is not complete functionality.

| Domain | Repository evidence | State | Release proof required |
|---|---|---|---|
| Android app shell | Flutter, GoRouter, Riverpod | Scaffold | Build/install on supported Android devices |
| Google sign-in | OAuth UI + callback docs | Partially wired | Provider config, redirect URI, Android callback and real login test |
| Friends/follow/discovery | Friend repository/screens, follow migration | Partial | End-to-end requests/accept/remove, pagination, block visibility/RLS |
| Private chat | legacy repository, realtime row stream | Legacy path | Full encrypted composer/inbox/realtime migration; plaintext disable |
| E2EE | envelope RPC, device registry, envelope repo | Foundations only | audited protocol, secure key storage, two-device crypto tests |
| Stranger matching | queue RPC, reservation RPC, consent/eligibility gates | Backend foundation | worker deployment, atomic queue lifecycle, filter semantics, realtime state |
| Private audio/video calls | call model/repo, incoming screen, WebRTC controller | Scaffold | request→accept, authenticated signaling, TURN, ICE/network/device tests |
| Translation | feature design/spec | Not verified in source | consent UI, provider adapter, captions/original audio fallback, cost controls |
| Moderation/safety | policy/spec and reports design | Not verified end-to-end | block/report/appeal, case access controls, retention and abuse tests |
| Wallet/VIP/gifts | design scope | Not verified in source | provider sandbox, ledger reconciliation, fraud controls, webhook signatures |
| Web/PWA | no verified app source/routes in audit | Not present/verified | complete responsive web client, installability, parity matrix |
| Admin/Ops | no verified admin source/routes in audit | Not present/verified | separate protected console, least privilege, audit, emergency controls |
| CI | Flutter quality workflow | Running/needs green evidence | format/analyze/tests all green |
| Supabase environment | migrations in repo; no confirmed VibeMingle staging project | Not applied | dedicated project ID confirmed, staged migration + RLS tests |
| Release | runbook exists | Not approved | full regression, privacy/security review, backup/restore, rollback rehearsal |

## Scope invariants
- Do not label a scaffold as shipped, or an RPC as a fully operational user flow.
- Do not broaden matching filters silently.
- Do not expose stranger GPS or private message contents to operators.
- No production migration, deployment, or launch without explicit owner review.
- Use free-tier services only unless owner separately approves any paid plan or usage.
- Keep implementation advancing toward the full V4.1 scope; these gates are not permission to cut features.
