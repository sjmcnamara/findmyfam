# Release Checklist

## Before Cut

1. Confirm target branch and version number.
2. Bump version in all three places:
   - `project.yml` — `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION`
   - `android/app/build.gradle.kts` — `versionName` + `versionCode`
   - `CHANGELOG.md` — add new version section at top
3. Update `ROADMAP.md` to reflect completed milestones.
4. Run `xcodegen generate` to apply version changes to the Xcode project.

## Validation

1. Run CI checks locally:
   - `cd WhistleCore && swift test`
   - `swiftlint lint --strict`
   - `cd android && ./gradlew :shared:test :app:testDebugUnitTest`
2. Push branch — all 5 CI jobs must pass (required merge gate).
3. Smoke test critical flows on device:
   - Create group, invite/join, leave/confirm leave, rejoin
   - Relay toggle (disable all → reconnect), add custom relay
   - Burn identity → verify clean slate
   - Nearby share / NFC path (if applicable)
4. Verify no regressions in group list visibility/state badges.

## PR Hygiene

1. Keep PR description focused on user-visible behaviour changes.
2. Include test evidence and known environment caveats.
3. Ensure any UI text changes are reflected in screenshots if needed.

## Post-Merge

1. Pull latest `master`.
2. Re-run smoke checks if release branch was long-lived.
3. Tag release: `git tag v1.0.0 && git push origin v1.0.0`
