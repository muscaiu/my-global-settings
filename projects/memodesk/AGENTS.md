# memodesk Project Guidance

## Start Here

- `CHANGELOG.md` is historical release documentation. Read it for context, but never modify it unless the user explicitly asks for a changelog or release update.
- **memodesk** is a pnpm monorepo for an offline-first personal notes/organizer app backed by Appwrite: a Vite + React PWA plus a separate Expo native mobile app — not a WebView wrapper. Both share sync/storage/service logic through `packages/shared`.
- Before changing code, check `git status --short` and recent commits if context is unclear.

## Versioning And Releases

- Never update `CHANGELOG.md`, the `apps/web/package.json` version, `apps/mobile/package.json`/`app.json` version fields, release notes, release tags, or service-worker/cache versions unless the user explicitly requests that specific versioning or release work.
- Feature work, bug fixes, builds, and tests do not imply permission to make versioning or changelog changes.
- Do not run commands that automatically bump versions or update release metadata unless explicitly requested.
- An explicit release request grants permission for that release's versioning work and requires following `RELEASE.md`. Mobile's `ios.buildNumber`/`android.versionCode` and any actual EAS build/submit step stay out of scope until a real store target exists — see `RELEASE.md` for why.

## Monorepo Layout

```text
apps/web/          Vite + React PWA (TanStack Router, Dexie, Appwrite)
apps/mobile/        Expo native app (Appwrite, SQLite, own UI) — shares logic with web via packages/shared
packages/shared/    Cross-app workspace package: Appwrite client, sync engine, storage adapters, notes/projects services, auth validation
```

Key web paths:

```text
apps/web/src/app/router.tsx          TanStack Router setup
apps/web/src/app/routes/              Route definitions (__root, index, login)
apps/web/src/features/                Feature components (auth/LoginForm, notes/NotesInbox)
apps/web/src/context/                 React providers (auth-context)
apps/web/src/services/                App-level service functions (notes.ts)
apps/web/src/lib/appwrite/            Appwrite client + database/collection IDs
apps/web/src/lib/db/                  Dexie schema — local offline IndexedDB store
apps/web/src/lib/sync/                Sync engine reconciling the Dexie outbox with Appwrite
apps/web/src/pwa/                     Service worker registration + version manager
apps/web/scripts/setup-appwrite.mjs   Idempotent Appwrite schema provisioning (Node, reads root .env.local)
```

Key shared paths:

```text
packages/shared/src/appwrite/create-client.ts   Appwrite client factory used by both apps
packages/shared/src/sync/engine.ts              Cross-platform sync engine
packages/shared/src/services/                    notes.ts, projects.ts
packages/shared/src/storage/                      Storage adapter interface + testing/adapter-contract.ts
packages/shared/src/auth/validate-credentials.ts
```

## Common Commands

Run from the repo root:

```bash
pnpm dev              # web dev server
pnpm build             # update service worker version, then build web
pnpm lint              # lint web app
pnpm preview           # preview production build
pnpm setup-appwrite    # provision Appwrite database/collections from root .env.local
pnpm update-sw         # sync apps/web/public/sw.js version with package.json
pnpm test              # runs both apps/web and apps/mobile tests

pnpm mobile             # Expo dev server (Expo Go — quick JS-only testing)
pnpm mobile:dev         # Expo dev server (dev-client — real icon/splash)
pnpm mobile:ios
pnpm mobile:android
pnpm --filter memodesk-mobile typecheck
```

## Architecture Notes

- Web stack: Vite, React 19, TypeScript, TanStack Router, Dexie (IndexedDB), Appwrite, oxlint.
- Offline-first: writes land in Dexie immediately (optimistic) and are queued in an outbox table; the sync engine drains the outbox to Appwrite with exponential backoff, then pulls remote changes using an updated-at cursor. It runs on load, on `online`, on tab visibility, and periodically.
- Auth: Appwrite email/password sessions.
- `VITE_*` env vars are the browser-facing Appwrite config (endpoint/project/database). `APPWRITE_API_KEY` is server-only.
- Mobile: a real Expo native app with its own Appwrite client (`react-native-appwrite`) and SQLite storage, not a WebView shell. It shares sync/storage/service logic with web through `packages/shared`'s storage-adapter pattern rather than loading the deployed web app.
- PWA: hand-rolled versioned service worker (`apps/web/public/sw.js`), not a generator plugin — a build script keeps its version in sync with `package.json` on every build.
- EAS project is configured (`eas.json`, `app.config.ts`) but there is no App Store Connect app or confirmed Play Console listing yet — see `RELEASE.md`.
