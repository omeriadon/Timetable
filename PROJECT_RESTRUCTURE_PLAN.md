# Timetable Rebuild Plan

## Non-negotiable architecture

- SwiftUI views, widgets, App Intents, snippets, and Spotlight read persistent state only through `Defaults`.
- Only Wallet infrastructure may call `PKPassLibrary`; it projects Wallet state into `Defaults[.receivedTimetables]`.
- The owner timetable lives in `Defaults[.timetable]` independently of Wallet and syncs to the account server after authentication.
- iOS treats Wallet as authoritative for received timetables. macOS, visionOS, and watchOS use the server projection.
- watchOS receives credentials and account state from its paired iPhone, then fetches timetable data directly from the server.
- Views use focused `@Default(.key)` declarations. No `ObservableObject`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject`.
- Shared mutable services use `@MainActor @Observable` only when they expose transient command state.
- Existing UI remains visually intact. `SettingsView` is split into focused sections as features are added.
- No legacy migration work is required during this rebuild.

## Shared account state

`AccountSettings` remains a separately codable, server-synchronised value with one setting:

```swift
struct AccountSettings: Codable, Hashable, Sendable {
	var liveActivitiesEnabled: Bool
}
```

Shared Defaults keys will include the owner timetable, received timetables, account profile, display name, received-name overrides, wallet revision, reconciliation timestamps, account bootstrap status, installation identifier, and `AccountSettings`.

Functions that operate on data already stored in Defaults read that key internally. Explicit-value overloads are reserved for deterministic unit tests.

## Received timetable identity and deletion

`ReceivedTimetable.id` and `issuerAccountID` are strings. For `.accountOwner`, `id == issuerAccountID`. For `.authoredForThirdParty`, `id` is the server-generated pass serial number.

Every received timetable and pass payload contains `isDeleted`. Deletion works as follows:

1. The server marks the pass record deleted and generates a final updated pass.
2. The first Wallet back field states that the timetable was deleted and will be removed.
3. PassKit update pushes notify registered devices.
4. Wallet reconciliation detects the deletion tombstone and immediately calls `PKPassLibrary.removePass(_:)`.
5. The deleted item is excluded from Defaults and the resulting projection is uploaded.
6. Server-backed platforms remove the item when they refresh Defaults.
7. The server retains a revocation tombstone so an old pass cannot become active again.

## Server

`pmstt` follows the existing `moneyServer` layout and conventions for Fluent models, PostgreSQL, migrations, route collections, DTO validation, Bcrypt, token authentication, profile updates, and account deletion.

Models are introduced one at a time: `User`, `UserToken`, `OwnerTimetable`, `AuthoredTimetable`, `PassRecord`, `PassRegistration`, `ReceivedPassMirror`, `ReceivedNameOverride`, and `UserDevice`. Each model receives a dedicated review, implementation, test, Xcode build, and commit.

Sessions use short-lived access tokens and long-lived rotating refresh tokens. Refresh tokens are hashed server-side and stored in Keychain on clients. Silent refresh prevents routine sign-in prompts.

Server responses use stable error codes, human-readable messages, request identifiers, and appropriate HTTP status codes so endpoints remain straightforward to inspect with RapidAPI.

## Client networking

`NetworkManager.swift` is a single structured file divided with `// MARK: -` sections for state, reachability, authentication, requests, response validation, decoding, uploads, downloads, errors, and logging.

Before creating a request, `NetworkManager` verifies reachability. A known-offline request is rejected locally and sets a top-level transient alert. The root content view owns that alert presentation. One `401` triggers silent token refresh and one retry.

## Settings structure

The current settings UI is split without changing its visual design:

- Profile section
- Account and authentication section
- Live Activities section
- Wallet and received timetables section
- Sync and diagnostics section
- Destructive account actions section

Each section is a focused SwiftUI type in the existing Settings folder. It imports only the Defaults keys and command services it needs.

## Logging and performance

Extend `Print` and `PrintError` with categories, function names, durations, and redaction. Instrument service boundaries, controllers, routes, reconciliation, persistence, authentication, Wallet, network, PassKit generation, Live Activities, and failures.

Never log credentials, complete APNs tokens, pass authentication tokens, or raw private payloads. Hot rendering and school-state functions use debug-only or rate-limited logging. No network calls, pass parsing, indexing, large mapping operations, or state calculation may run in SwiftUI `body`.

## School state, widgets, intents, and Spotlight

School-state behavior moves into a typed `SchoolStateEngine` enum namespace. Public convenience functions read Defaults internally. Pure calculation overloads accept explicit inputs for tests. Compact value types such as `Slot` and `TimeOfDay` retain unlabeled initializers.

Every timetable-sensitive current date comes from `TimetableClock.now`, which always applies `debugOffset`.

Widget providers read Defaults and construct complete entries. Widget views render entries only. Widget timers use `Text(timerInterval:countsDown:)`. Layout-sensitive widgets and intent snippets use `.dynamicTypeSize(.medium)`.

App Intent queries and Spotlight indexing read Defaults internally. Spotlight uses stable identifiers and rebuilds after Defaults changes, never directly after Wallet events.

## Implementation order

1. Establish warning-free Xcode baselines for every existing scheme and both server projects.
2. Commit this architecture document.
3. Add structured client logging.
4. Configure `pmstt` persistence, structured errors, request IDs, and tests.
5. Add and verify the `User` model.
6. Add and verify secure `UserToken` sessions.
7. Add authentication and profile routes.
8. Add the client `NetworkManager` and root alert presentation.
9. Add client session state and phone-to-watch credential synchronisation.
10. Add the remaining server models individually.

Later phases add timetable APIs, server pass generation, PassKit web services, Defaults model replacement, Wallet tombstone reconciliation, server projections, account bootstrap UI, school-state refactoring, widgets, intents, Spotlight, Live Activities, account deletion, and removal of CloudKit/device-ID/client-signing infrastructure.

## Build and commit gate

For every implementation unit:

1. Inspect repository state.
2. Change one behavior.
3. Run focused tests.
4. Build every affected scheme through the Xcode integration.
5. Stop on any warning or error.
6. Repair and rebuild the same unit.
7. Inspect the diff for unrelated changes.
8. Commit only the verified unit.
9. Begin the next unit only after the commit succeeds.

Never use `xcodebuild` for verification. Never commit secrets, `.env` files, certificates, generated passes, build output, or unrelated user changes.
