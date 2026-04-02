# Testing and CI

## CI Pipeline

GitHub Actions runs automatically on PRs to `master` and pushes to `master`. All checks are required merge gates.

| Job | Runner | What it does |
|-----|--------|-------------|
| `WhistleCore Tests` | macOS 15 | `swift test` on the shared SPM package |
| `iOS Build & Test` | macOS 15 | Full Xcode build + `WhistleTests` on iPhone 16 simulator |
| `Android Build & Test` | Ubuntu | `:shared:test` + `:app:testDebugUnitTest` via Gradle |
| `SwiftLint` | macOS 15 | `swiftlint lint --strict` — any warning fails the build |
| `Dependency Review` | Ubuntu | Scans PR dependency changes for known vulnerabilities (PR only) |

Dependabot checks weekly for updates to GitHub Actions, Swift packages, and Gradle dependencies.

## Local Test Commands

### iOS

```bash
# WhistleCore (pure Swift, fast)
cd WhistleCore && swift test

# Full app tests (requires Xcode + simulator)
xcodebuild test \
  -project Whistle.xcodeproj \
  -scheme Whistle \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" \
  -only-testing:WhistleTests
```

### Android

```bash
cd android
./gradlew :shared:test          # shared module
./gradlew :app:testDebugUnitTest # app unit tests
```

### SwiftLint

```bash
swiftlint lint --strict
```

## Common Local Issues

- Simulator destination mismatch — use `xcrun simctl list devices available` to find valid names
- Stale build cache — `rm -rf WhistleCore/.build` if PCH errors appear
- Xcode project out of date — run `xcodegen generate` after pulling

## Test Focus Areas

- `MarmotServiceTests`: gift-wrap retry, pending ID retry path, join reliability
- `GroupHealthTrackerTests`: failure tracking and unhealthy thresholds
- `IdentityServiceTests`: key generation, persistence, import, destroy
- `EncryptedSecureStorageTests`: SE wrapping, migration detection, Data methods
- `SecureEnclaveServiceTests`: P-256 ECDH + AES-GCM round-trips, key serialization
- `PendingWelcomeStoreTests` / `PendingLeaveStoreTests`: consent and leave flows
- Payload and store tests for persistence/encoding correctness

## When to Add Tests

- Any change to join/leave/rejoin logic
- Any change to pending state stores
- Any change to event processing retries or error handling
- Any change to key storage or encryption
- Any change to relay connectivity
