# Release Checklist

## Before Cut

1. Confirm target branch and version number.
2. Verify app version in `SettingsView` About section.
3. Update `CHANGELOG.md` for the release.
4. Ensure `ROADMAP.md` reflects completed milestones.

## Validation

1. Run unit tests locally.
2. Smoke test critical flows:
   - create group
   - invite/join
   - leave/confirm leave
   - rejoin
   - Nearby share path
3. Verify no regressions in group list visibility/state badges.

## PR Hygiene

1. Keep PR description focused on user-visible behavior changes.
2. Include test evidence and known environment caveats.
3. Ensure any UI text changes are reflected in screenshots if needed.

## Post-Merge

1. Pull latest `master`.
2. Re-run smoke checks if release branch was long-lived.
3. Tag release when appropriate.
