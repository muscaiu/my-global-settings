# Costility Release Workflow

Create, test, merge, and deploy a Costility release. Complete every step; do not treat any step as optional.

The invoking `/release` command provides the user's arguments. Supported arguments are:

- `patch`, `minor`, or `major`
- Optional `ios <version> <build>` override
- Optional `android <version> <versionCode>` override

If no valid bump type is provided, ask before changing files. Reject incomplete mobile override groups.

A mobile override means that exact store artifact must become the corresponding `MOBILE_RELEASES` entry so installed apps receive the update prompt. Validate that the artifact is publicly downloadable first. If it cannot be validated, stop the release; never publish the web release with a supplied mobile override omitted from the registry.

## 1. Inspect

- Read `apps/web/package.json` and calculate the requested semantic version bump.
- Check git status, the complete diff since the last release, and recent commits.
- Classify native changes as iOS, Android, both, or neither. WebView-hosted changes alone are web-only.
- Never infer one platform's release from the other platform, the web version, Expo Go, or proposed values in mobile config.

## 2. Reconcile Store Releases

`apps/web/src/lib/mobile-releases.ts` records actual downloadable store artifacts and drives installed-app update prompts. Its `BLOCKED_MOBILE_RELEASES` entries are quarantined releases that must never be promoted.

Perform store reconciliation on every release, even when the current diff is web-only and even when no mobile override was supplied.

### iOS

1. Fetch `https://itunes.apple.com/lookup?id=6780153943` and require exactly one result whose `bundleId` is `com.costility.app`.
2. Treat the returned `version` and `currentVersionReleaseDate` as Apple's public confirmation that the version is ready for distribution. Do not use `apps/mobile/app.config.ts` as proof of availability.
3. Run `pnpm --filter costility-mobile exec eas build:list --platform ios --status finished --distribution store --limit 20 --json --non-interactive`.
4. Match the public App Store version to a `FINISHED`, `STORE` EAS build with the same `appVersion`. Exclude builds completed after Apple's `currentVersionReleaseDate`; select the highest numeric `appBuildVersion` among the remaining matches.
5. Confirm the build commit exists in this repository. If an explicit `ios <version> <build>` override was supplied, require an exact EAS match and require Apple's public version to equal that version.
6. Compare the validated App Store version/build with `MOBILE_RELEASES.ios`. If the artifact appears in `BLOCKED_MOBILE_RELEASES.ios`, preserve the latest known-good registry entry and report the quarantine. Otherwise, if either value is newer, update both iOS fields before continuing. For an explicit override, the resulting registry entry must exactly equal the supplied version/build. This is mandatory regardless of affected-platform classification.
7. If Apple's public version is newer than the registry but no matching EAS build can be validated, stop the release instead of leaving a stale update registry.
8. If the lookup fails or returns invalid data, stop and report the lookup failure; do not silently skip iOS reconciliation.

### Android

- If Google Play credentials are available, reconcile the published production artifact against finished EAS store builds on every release.
- For an Android override or Android-native changes, require a matching finished store build and confirm its published track before updating `MOBILE_RELEASES.android`. For an explicit override, the resulting registry entry must exactly equal the supplied version/versionCode.
- Preserve the Android registry byte-for-byte when no newer published artifact can be validated or the artifact appears in `BLOCKED_MOBILE_RELEASES.android`. Never align it merely because iOS changed.

If current native changes require a store build that does not exist or is not yet publicly downloadable, stop before publishing and report the required mobile release.

## 3. Prepare Release Metadata

- Update `apps/web/package.json` to the new web version.
- Run `pnpm update-sw` from the repository root.
- Add a concise release section with today's date to `CHANGELOG.md` using the existing format.
- Include the store-registry change in the changelog when reconciliation updates a platform.
- Before verification, assert that every supplied mobile override exactly matches its `MOBILE_RELEASES` entry. Stop if any supplied override was not applied.
- Do not change unrelated package, mobile, or cache versions.

## 4. Verify

Run these commands from the repository root, sequentially and in this exact order:

1. `pnpm lint`
2. `pnpm build:verify`
3. `pnpm test:e2e`

Do not publish while any command fails. Fix release-caused failures and rerun the failed verification. Check git status afterward and include intended generated release changes.

## 5. Commit And Pull Request

- Create `release-X.Y.Z` from the current branch.
- Review `git status`, the complete diff, and recent commits before staging.
- Stage only intended release files, including `apps/web/src/lib/mobile-releases.ts` whenever store reconciliation changed it.
- Commit with `X.Y.Z: brief description of key changes`.
- Confirm `gh auth status`, determine the default branch with `gh repo view`, push with upstream tracking, and create a PR against the default branch.
- Use the exact commit message as the PR title and include concise change and verification summaries.

## 6. Checks, Merge, And Production

- Poll PR checks for up to two minutes. Watch every registered check and stop on failure or cancellation.
- If no checks register, record that fact and rely on the mandatory local verification.
- After all checks pass, merge with `gh pr merge <PR> --merge --delete-branch`. Never bypass checks.
- Read the merge commit SHA from the merged PR.
- Wait for a Production deployment whose SHA exactly matches the merge commit. Allow 15 minutes for creation and 20 minutes for completion.
- Report success only after the production deployment succeeds. If GitHub deployment data is unavailable, use the configured Vercel token without printing it to inspect the matching `costility` deployment.

## Final Output

Report concisely:

- Release version and exact commit message
- iOS and Android registry values, identifying changed and preserved entries
- PR URL and merge commit SHA
- Local verification and PR checks
- Production status and URL, or the exact blocker URL
