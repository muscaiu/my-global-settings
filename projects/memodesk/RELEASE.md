# memodesk Release Workflow

Create, test, merge, and deploy a memodesk release. Complete every step; do not treat any step as optional.

The invoking `/release` command provides the user's arguments. Supported arguments are:

- `patch`, `minor`, or `major`

If no valid bump type is provided, ask before changing any files.

Mobile has no App Store Connect or Play Console listing yet, even though an EAS project is configured (`eas.json`, `app.config.ts`). Every release keeps `apps/mobile`'s version fields in lockstep with web for consistency, but never builds, submits, or touches `ios.buildNumber`/`android.versionCode`. Revisit this workflow (add store reconciliation against `eas build:list` and the App Store/Play Console, plus a `MOBILE_RELEASES`-style registry) once a real store target exists — see `AGENTS.md`.

## 1. Inspect

- Read `apps/web/package.json` for the current version and calculate the requested semantic version bump.
- Check git status, the complete diff since the last release, and recent commits.
- Note whether changes touch `apps/mobile`, `apps/web`, or `packages/shared` — used later for changelog prefixes, not to skip any verification step. `packages/shared` (Appwrite client, sync engine, storage adapters) is used by both apps, so a change there can affect both.

## 2. Prepare Release Metadata

- Update `apps/web/package.json` to the new version.
- Update `apps/mobile/package.json`'s `version` and `app.json`'s `expo.version` to the same new version number — keep web and mobile in lockstep.
- Do NOT touch `apps/mobile/app.json`'s `ios.buildNumber` or `android.versionCode` — those are native build counters tied to actual store submissions, which don't exist yet.
- Run `pnpm update-sw` from the repository root to sync `apps/web/public/sw.js`'s version.
- Add a concise release section with today's date to `CHANGELOG.md`, following the existing format (see Changelog Generation below). Separate it from the release below with a `---` line: blank line, `---`, blank line, then the next `## [` heading.
- Do not change unrelated package, mobile, or cache versions.

## 3. Verify

Run these commands from the repository root, sequentially and in this exact order:

1. `pnpm lint`
2. `pnpm --filter memodesk-mobile typecheck`
3. `pnpm test` (covers both `apps/web` and `apps/mobile`)
4. `pnpm build`

Never run these concurrently — start the next command only after the previous one exits successfully. Do not publish while any command is failing. Fix release-caused failures and rerun the failed verification; otherwise report the blocker. Check `git status` afterward and include any build-generated release changes (e.g. the updated service worker) in the commit.

## 4. Commit And Pull Request

- Create `release-X.Y.Z` from the current branch.
- Review `git status`, the complete diff, and recent commits before staging.
- Stage only intended release files.
- Commit with `X.Y.Z: brief description of key changes`.
- Confirm `gh auth status`, determine the default branch with `gh repo view`, push with upstream tracking, and create a PR against the default branch using the exact commit message as its title.

## 5. Checks, Merge, And Production

- Poll `gh pr view <PR> --json statusCheckRollup` for up to two minutes. Watch every registered check with `gh pr checks <PR> --watch --fail-fast`; stop on failure or cancellation.
- If no checks register, record that fact and rely on the mandatory local verification from step 3.
- After all checks pass, merge with `gh pr merge <PR> --merge --delete-branch`. Never bypass checks.
- Read the merge commit SHA from `gh pr view <PR> --json mergeCommit`.
- Poll GitHub deployments for a `Production` deployment whose `sha` exactly matches the merge commit, then poll its status to `success`, `failure`, or `error`. Allow 15 minutes for creation and 20 minutes for completion.
- If GitHub deployment data is unavailable, source `.env.release` (never printing it) and use `VERCEL_TOKEN` with `npx --yes vercel@latest` to check the matching `memodesk` deployment.

## Changelog Generation

**CRITICAL: Keep changelog entries SHORT and SIMPLE. Avoid verbose descriptions and bullet point lists.**

When analyzing changes for the changelog, prioritize:

1. **User-facing features** - What users will notice and benefit from
2. **Technical improvements** - Performance, architecture, code quality
3. **Bug fixes** - Issues resolved and bugs squashed
4. **Breaking changes** - What developers need to know when upgrading

**Writing Guidelines:**

- **One line per change** - Each bullet point should be a single, concise sentence
- **No nested bullets** - Avoid sub-bullets and detailed explanations
- **Focus on what, not how** - Describe what changed, not implementation details
- **Keep it brief** - If a description is longer than one sentence, make it shorter

Example of a good changelog entry:

```
### Changed
- **Notes inbox**: Pending sync count now shows next to the log-out button
- **Sync engine**: Retries now back off exponentially instead of at a fixed interval
```

When a change is specific to `apps/mobile` (not shared with web), prefix its bullet with **Mobile app**: (e.g. `- **Mobile app**: Notes now support drag-to-reorder in both list and grid view`), matching the label already used for prior mobile-only entries. Web changes and changes shared by both apps (including `packages/shared`) need no prefix.

## Version Bump Logic

### Patch (X.Y.Z → X.Y.Z+1)

- Bug fixes
- Small improvements
- Documentation updates
- Performance optimizations

### Minor (X.Y.Z → X.Y+1.0)

- New features
- Non-breaking changes
- New components or utilities
- Enhanced existing functionality

### Major (X.Y.Z → X+1.0.0)

- Breaking changes
- Complete redesigns
- Major architectural changes
- Incompatible dependency updates

## Final Output

Report concisely:

- Release version and exact commit message
- Local verification results (lint/typecheck/test/build) and PR checks
- PR URL and merge commit SHA
- Production status and URL, or the exact blocker URL
- Confirm `apps/mobile`'s version was bumped to match web, and note it wasn't built or deployed anywhere (no store target configured yet) — just kept in sync
