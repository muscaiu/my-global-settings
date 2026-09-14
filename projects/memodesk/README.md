# memodesk Project Profile

Reusable agent context for [memodesk](https://github.com/muscaiu/memodesk).

- `AGENTS.md` describes the repository, commands, and coding boundaries.
- `RELEASE.md` is the authoritative release strategy.
- `commands/release.md` is the thin `/release` launcher.

Unlike the Spend profile (a WebView-in-native-wrapper app), memodesk's mobile app is a genuinely separate Expo native app: it has its own Appwrite client, local SQLite storage, and its own UI, sharing sync/storage/service logic with web through `packages/shared` rather than loading the web app in a WebView. It also has no App Store Connect or Play Console listing yet, so its release workflow skips store reconciliation entirely (see `RELEASE.md`) — a difference from Spend's fuller store-validated flow.

When applying this profile to another repository, preserve the release phases and safety gates but replace memodesk-specific package paths, checks, monorepo layout, and deployment provider with validated equivalents from that repository.
