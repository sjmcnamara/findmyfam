# Troubleshooting

## Build Error: `Cannot find 'member' in scope`

Cause:
- `swipeActions` closure references `member` outside the `ForEach` item scope.

Fix:
- Move `.swipeActions` onto the row view inside the `ForEach` item closure.

## Join Succeeds for Admin but Invitee Cannot See Group

Cause:
- Stale pending leave marker still hiding rejoined group.

Fix:
- Clear pending leave state on join and on Welcome acceptance.

## Nearby Shows Generic Device Name

Cause:
- Display name falls back to default device name.

Fix:
- Pass app display name where available; fallback to device name.

## Gift-Wrap Retry Test Fails (expected 2 fetch filters, got 1)

Cause:
- `sut.settings` not injected in test setup, so pending IDs are not read.

Fix:
- Inject settings in test setup and set pending gift-wrap IDs explicitly.

## Simulator/Test Instability

Symptoms:
- `xcodebuild` exits with code `130`

Mitigation:
- Use explicit simulator destination.
- Re-run after cleaning project artifacts.
