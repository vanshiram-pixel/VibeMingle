# VibeMingle

**Connect Beyond Borders**

VibeMingle is planned as an adults-only global social/random video chat product with privacy, consent and safety at its core.

## Scope
The integrated V1 + V2 + V3 scope is tracked in `docs/product/V3_FINAL_INTEGRATED_SCOPE_LOCK.md` and the feature catalog in `docs/product/V3_COMPLETE_FEATURE_CATALOG.md`.

## Current repository status
- Product scope and feature catalog documented.
- Architecture and implementation plan documented.
- Initial TypeScript monorepo/API/web/admin scaffold added.
- CI currently checks repository hygiene only.
- Flutter workspace generation, database migrations, OAuth, matchmaking, LiveKit, AI, payments, moderation and production operations are **not implemented/verified**.

## Workspaces
- `apps/web`: public Next.js site
- `apps/admin`: protected Admin Console target (currently placeholder, not secured)
- `apps/mobile`: Flutter Android target (initialize with Flutter SDK)
- `services/api`: trusted Fastify API scaffold
- `packages/contracts`: shared TypeScript contracts
- `supabase/`: migration and policy work

## Local setup (Node 20.11+ / npm 10+)
```bash
npm install
npm run typecheck
npm run dev --workspace @vibemingle/api
```
API health: `http://127.0.0.1:4000/health`

Web:
```bash
npm run dev --workspace @vibemingle/web
```
Admin placeholder:
```bash
npm run dev --workspace @vibemingle/admin
```

> Admin is not authenticated yet. Do not expose it publicly or use it with real user data. The website and API are scaffolds, not a production service.

## Security
Use local ignored environment files and approved secret stores. Never commit credentials, service-role keys, provider secrets, user data or evidence.
