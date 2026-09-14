# Spend Project Guidance

## Start Here

- `CHANGELOG.md` is historical release documentation. Read it for context, but never modify it unless the user explicitly asks for a changelog or release update.
- This is a pnpm monorepo for Costility, a personal finance tracker.
- Before changing code, check `git status --short` and recent commits if context is unclear.

## Versioning And Releases

- Never update `CHANGELOG.md`, package or app version numbers, release notes, release tags, or service-worker/cache versions unless the user explicitly requests that specific versioning or release work.
- Feature work, bug fixes, builds, and tests do not imply permission to make versioning or changelog changes.
- Do not run commands that automatically bump versions or update release metadata unless explicitly requested.
- An explicit release request grants permission for that release's versioning work and requires following `RELEASE.md`.

## Monorepo Layout

```text
apps/web/          Next.js PWA/web app
apps/mobile/       Expo mobile WebView shell
packages/shared/   Shared Appwrite client, types, stores, and domain utilities
```

Key web paths:

```text
apps/web/src/app/          App Router routes; localized app routes live under [locale]/
apps/web/src/app/api/      API routes
apps/web/src/components/   Reusable UI and feature components
apps/web/src/contexts/     React providers
apps/web/src/i18n/         next-intl routing/navigation config
apps/web/messages/         en/ro message catalogs
apps/web/public/sw.js      PWA service worker
```

Shared package paths:

```text
packages/shared/src/lib/     Appwrite/database/csv/currency/share utilities
packages/shared/src/stores/  Zustand stores
packages/shared/src/types/   Shared TypeScript models
```

## Common Commands

Run from the repository root:

```bash
pnpm dev
pnpm build
pnpm build:verify
pnpm lint
pnpm test:e2e
pnpm test:e2e:i18n
pnpm mobile
pnpm mobile:ios
pnpm mobile:android
```

## Architecture Notes

- Web stack: Next.js App Router, React 19, TypeScript, Tailwind CSS 4, next-intl, Appwrite, Stripe, and a PWA service worker.
- Mobile is an Expo shell that hosts the web app in a WebView and uses shared bootstrap code.
- Appwrite data/auth logic that must work across web/mobile belongs in `packages/shared`; web-only behavior belongs in `apps/web/src`.
- Use locale-aware navigation helpers from `apps/web/src/i18n` for app routes.
- Keep `apps/web/messages/en.json` and `apps/web/messages/ro.json` in sync when adding UI copy.
- Root `.env.local` is loaded by `apps/web/next.config.ts`; `apps/web/.env.local` can override it.
