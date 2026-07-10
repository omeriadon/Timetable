# Timetable Continuation Plan

## Purpose

This document is the execution handoff for the remaining Timetable rebuild work after commit `aeedf2c` (`Add unified school state widgets and intents`). It describes the current implementation, the remaining client and server work, the contracts that must not be changed, the exact files to inspect, the required build commands, and the atomic commit order.

Do not restart from the old rebuild plan. Most server foundation work and a large portion of the client architecture already exist. Work from the current source tree and this document.

## Project locations

- Client application: `/Users/omeriadon/Documents/Xcode_App_Library/Timetable`
- Server: `/Users/omeriadon/Documents/Xcode_App_Library/pmstt`
- Client Xcode project: `/Users/omeriadon/Documents/Xcode_App_Library/Timetable/Timetable.xcodeproj`
- Server Swift package: `/Users/omeriadon/Documents/Xcode_App_Library/pmstt/Package.swift`

## Supported platforms

- iOS
- iPadOS through the iOS target
- macOS
- watchOS
- iOS Widget extension
- watchOS Widget extension

visionOS is not supported. Do not add visionOS destinations, build settings, conditionals, tests, documentation, or acceptance criteria.

## Required build tool

Use `xcodebuild`. The active `xcode-select` path points at Command Line Tools, so every Xcode command must set:

```sh
DEVELOPER_DIR='/Applications/Xcode 27 beta 3.app/Contents/Developer'
```

Primary client build commands:

```sh
DEVELOPER_DIR='/Applications/Xcode 27 beta 3.app/Contents/Developer' \
xcodebuild \
  -project Timetable.xcodeproj \
  -scheme Timetable \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  build \
  CODE_SIGNING_ALLOWED=NO
```

```sh
DEVELOPER_DIR='/Applications/Xcode 27 beta 3.app/Contents/Developer' \
xcodebuild \
  -project Timetable.xcodeproj \
  -scheme Timetable \
  -configuration Debug \
  -destination 'generic/platform=macOS' \
  build \
  CODE_SIGNING_ALLOWED=NO
```

The Timetable iOS scheme builds the embedded Widget, Watch, and Watch Widget dependency graph. This is currently the reliable watch compilation gate.

The standalone `Watch` scheme currently fails from the command line because Xcode looks for iPhoneOS `MaterialView.o` products while resolving the companion target. Do not treat that product-path error as a Swift source failure. Diagnose the scheme/configuration separately during final build cleanup. Do not hide genuine Watch Swift errors behind this known issue.

Server gates:

```sh
cd /Users/omeriadon/Documents/Xcode_App_Library/pmstt
swift build -c release
```

Run `swift test` only when changing the existing Live Activity scheduler/projector tests or another server behavior that already has a directly relevant suite.

## Repository state at handoff

### Timetable client

The client repository was clean immediately after commit `aeedf2c`, before this document replacement.

The commit hook runs SwiftFormat. During `aeedf2c`, that hook formatted and automatically included all pre-existing dirty client files, not only the explicitly staged paths. No source work was lost. The commit is broader than its intended staged unit and includes the pre-existing Spotlight, notification, subject metadata, localization, and Live Activity UI edits.

Do not attempt to split or rewrite `aeedf2c`. Continue forward with new atomic commits.

### pmstt server

The server has one uncommitted change owned by the existing work:

```text
M Sources/pmstt/Services/LiveActivities/SchoolDayActivityProjector.swift
```

The change makes the `next` argument to `lesson(...)` optional:

```swift
private func lesson(
    period: Int,
    date baseDate: Date,
    dayIndex: Int,
    subjects: [TimetableSubjectDTO],
    next: String?,
    end: (Int, Int)
) -> SchoolDayActivityContentState
```

Preserve this change. Validate and commit it only as part of the Live Activity projector unit described below.

## Completed implementation

### Server foundation

The server already contains:

- PostgreSQL and Fluent configuration.
- Structured error responses and request IDs.
- `User`, `UserToken`, `OwnerTimetable`, `AuthoredTimetable`, `ReceivedPassMirror`, `ReceivedNameOverride`, `UserDevice`, `PassRegistration`, and `PassRecord` models and migrations.
- Email authentication, Sign in with Apple, refresh, logout, profile, and account deletion routes.
- Owner, authored, received, settings, device, discovery, report, notification, PassKit web-service, and Live Activity controllers.
- Pass generation and signing.
- Wallet update push infrastructure.
- Notification scheduling and APNs infrastructure.
- Persistent Live Activity records and transition claims.
- Push-to-start and update-token endpoints.

Do not recreate these systems.

### Client account and synchronization foundation

The client already contains:

- `NetworkManager` with authentication refresh and structured server errors.
- `SessionStore` with Keychain-backed credentials and silent refresh.
- Paired-iPhone watch provisioning through WatchConnectivity.
- Owner timetable server synchronization.
- Received timetable projection synchronization.
- Account settings synchronization.
- APNs device registration.
- Live Activity token registration.

Watch authentication remains paired-iPhone provisioned. Never add independent signup, email login, or Sign in with Apple to watchOS.

### Unified school-state engine

Commit `aeedf2c` replaced the legacy global `getSchoolState` API with:

- `TimeOfDay`
- `SchoolPeriod`
- `SchoolInterval`
- `ScheduledSubject`
- `CurrentLesson`
- `CurrentFreePeriod`
- `BreakState`
- `SchoolStateDestination`
- `SchoolState`
- `ReceivedSchoolState`
- `TimetableClock`
- `SchoolStateEngine`

The formal state cases are:

```swift
case beforeSchool(next: ScheduledSubject)
case lesson(CurrentLesson)
case freePeriod(CurrentFreePeriod)
case recess(BreakState)
case lunch(BreakState)
case afterSchool
case weekend
case noTimetable
```

All current client, watch, widget, and Current Subject intent consumers were migrated to this engine. Do not reintroduce `getSchoolState`, tuple-based intervals, or optional current-subject state.

All timetable-sensitive current-time access must use `TimetableClock.now`. Timeline-provider calculations for an explicit real date may use `TimetableClock.adjusted(date)`.

### Widgets

The active widget set is deliberately limited to:

1. Weekly timetable.
2. Next break.
3. Friends' current subjects.
4. School-day Live Activity.

The old standalone Time Left widget was removed.

The weekly timetable is now configurable with `WeeklyScheduleConfigurationIntent`. Its Person picker defaults to the owner and can select an active received timetable.

The Next Break widget supports system-small and accessory-rectangular presentation where the platform supports those families.

All timeline widgets now provide representative placeholders and apply `.redacted(reason: .placeholder)`.

Do not add School Day Progress or Shared Free Period widgets. Do not add widgets merely because an intent exists. New widgets require a distinct, useful glanceable purpose.

### App Intents and Siri

Implemented entities and queries:

- `TimetableEntity`
- `SubjectEntity`
- `PersonTimetableEntity`
- `SchoolDayEntity`
- `TimetableQuery`
- `SubjectQuery`
- `PersonTimetableQuery`
- `SchoolDayQuery`

Implemented intents:

- Current Subject
- Next Subject
- Next Break
- Subjects for Day
- Get Timetable for Person
- Get Received Timetables

Implemented Siri shortcut phrases are registered in `App Intents/TimetableShortcuts.swift`.

Do not implement School Day Progress or Shared Free Period intents unless the product scope is explicitly reopened.

### Cross-platform build fixes

- `SymbolPickerSheet` uses `SFSymbolsPicker` only on iOS and provides a macOS fallback.
- The iOS launch storyboard is platform-filtered out of macOS resource compilation.
- The URL scheme `timetable://` is registered for widget and Spotlight navigation.

## Architecture rules that remain binding

1. Views, widgets, App Intents, snippets, and Spotlight read persistent timetable/account data through Defaults.
2. Only Wallet infrastructure may instantiate or call `PKPassLibrary`.
3. Wallet infrastructure reconciles Wallet state into Defaults. Presentation code never reads Wallet.
4. Use `@Default(.key)` for the smallest required persistent state in SwiftUI views.
5. Do not introduce `ObservableObject`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject`.
6. Shared mutable service state uses `@MainActor @Observable`.
7. Services are passed into views only for commands or transient progress/error state.
8. Preserve current UI designs unless a remaining task explicitly requires a new surface.
9. Do not introduce CloudKit as a timetable source of truth.
10. Do not synchronize timetable payloads through WatchConnectivity.
11. The owner timetable always exists locally independently of account or Wallet state.
12. Received timetable signed identity is immutable. Local names remain overrides keyed by pass serial number.
13. Do not widen `AccountSettings` from the checked-in client/server contract without explicit product approval.
14. No visionOS work.
15. Keep commits behavior-scoped and build before each commit.

## Remaining execution order

Complete the remaining work in the order below. Do not combine these units into one commit.

---

## Unit 1: Complete Spotlight indexing and navigation — completed

### Goal

Make the owner timetable, active received timetables, and subjects searchable with stable metadata and functional deep links. Remove deleted/tombstoned records immediately.

### Primary files

- `App Intents/Entities/Spotlight.swift`
- `App Intents/Entities/TimetableEntity.swift`
- `App Intents/Entities/SubjectEntity.swift`
- `App Intents/Queries/TimetableQuery.swift`
- `App Intents/Queries/SubjectQuery.swift`
- `Main/TimetableApp.swift`
- `Main/Tabs/ContentView.swift`
- `Main/Tabs/Timetable/TimetableView.swift`
- `Main/Backend/OwnerTimetableSyncService.swift`
- `Main/Backend/ReceivedTimetableSyncService.swift`
- `App Shared/Wallet/TimetablePassManager.swift`
- `Main/Views/Subject Editor/main sheet.swift`

### Current state

Implemented in the current working tree. Spotlight now rebuilds through a coalesced task, indexes owner and active received projections with stable timetable and subject identifiers, filters tombstones in entity queries, and routes typed timetable/subject deep links to the selected timetable and slot.

### Implemented

1. Defined stable Spotlight identifiers.
   - Owner timetable: `timetable.owner`.
   - Received timetable: `timetable.received.<serial>`.
   - Owner subject: `subject.owner.<normalized-subject-id>`.
   - Received subject: `subject.received.<serial>.<normalized-subject-id>`.
2. Entity display metadata continues to use the existing App Entity representations, with subject IDs scoped by timetable to prevent collisions.
   - Display title.
   - Signed or locally overridden person name.
   - Subject name.
   - Source kind.
   - Keywords including timetable, subject, teacher, and classroom where available.
   - `timetable://timetable` or a more specific stable URL.
3. Subject identifiers are scoped by owner/received timetable.
4. Added explicit indexer methods:

```swift
func rebuildFromDefaults() async
func indexOwnerTimetable() async
func indexReceivedTimetables() async
func removeDeletedTimetables() async
func removeAll() async
```

5. Rebuild triggers were added after owner downloads, received projection changes/deletions, Wallet reconciliation, and account bootstrap's initial rebuild:
   - Owner timetable mutation.
   - Received projection replacement.
   - Wallet reconciliation.
   - Name override update/removal.
   - Account bootstrap.
   - Account deletion/sign-out cleanup if local indexes should disappear.
6. Spotlight URLs route through `TimetableDeepLink`.
7. Specific received timetables are selected in `TimetableView`.
8. Subject deep links select their timetable and indexed slot when present.
9. Indexing remains outside SwiftUI `body`.
10. Rapid rebuilds cancel and coalesce through a short debounce.

### Verification

- `git diff --check` passed.
- Xcode build and manual deep-link/entity verification remain pending.

### Commit

```text
Complete timetable Spotlight indexing
```

---

## Unit 2: Replace the legacy Wallet manager with deterministic reconciliation — completed

### Goal

Make iPhone Wallet reconciliation a complete replacement projection, remove tombstoned passes deterministically, prevent stale pass resurrection, and coalesce Wallet notifications.

### Primary client files

- `App Shared/Wallet/TimetablePassManager.swift`
- `Shared/Wallet/toReceivedTimetable.swift`
- `Main/Backend/ReceivedTimetableSyncService.swift`
- `Shared/Defaults.swift`
- `Shared/Models/ReceivedTimetable.swift`
- `Main/TimetableApp.swift`

### Primary server files

- `Sources/pmstt/Models/PassRecord.swift`
- `Sources/pmstt/Controllers/AuthoredTimetableController.swift`
- `Sources/pmstt/Controllers/AccountController.swift`
- `Sources/pmstt/Controllers/WalletWebServiceController.swift`
- `Sources/pmstt/Services/Passes/PassFactory.swift`
- `Sources/pmstt/Services/Passes/WalletPushService.swift`
- `Sources/pmstt/Services/Passes/generatePass.swift`

### Implemented

The client manager now:

- Observes `PKPassLibraryDidChange`.
- Parses timetable passes.
- Removes passes whose payload says `isDeleted`.
- Removes passes whose serial appears in `receivedTombstoneIDs`.
- Rebuilds the received projection as a complete replacement from currently installed active passes.
- Uploads the resulting projection after reconciliation.

The server already:

- Marks pass records deleted.
- Generates deleted-pass responses.
- Includes `isDeleted` in pass user info.
- Serves deleted passes from the PassKit web service.
- Pushes Wallet updates.

The client now uses `WalletTimetableReader`, coalesces Wallet notifications, prevents overlapping reconciliation tasks, updates reconciliation timestamps, increments wallet revisions only for effective projection changes, reloads widgets, and rebuilds Spotlight after changes. Pass deletion matches stable serial IDs. The server retains deleted `PassRecord` revocation tombstones after registrations are removed.

### Verification

- `git diff --check` passed.
- Client and server builds, relevant server tests, and physical Wallet tests remain pending.

### Existing correctness defects

1. Client reconciliation merges newly observed passes into the existing Defaults dictionary. This can preserve a pass that was removed from Wallet.
2. `deletePass(for:)` matches sender and received timestamp instead of stable serial ID.
3. Wallet notifications are not coalesced.
4. A new task can overlap an existing reconciliation.
5. `isLoading` can remain true on early failure.
6. The manager mixes reader, reconciliation, command, state, animation, and upload responsibilities.
7. Wallet infrastructure uses `withAnimation`, which is presentation behavior inside persistence infrastructure.
8. Server `WalletWebServiceController.unregister` deletes a deleted `PassRecord` after its final registration disappears. That conflicts with the requirement to retain a revocation tombstone so an old `.pkpass` cannot be reimported as active.

### Required client implementation

1. Introduce a pure reader:

```swift
struct WalletTimetableReader {
    func timetablePasses() -> [PKPass]
    func decode(_ pass: PKPass) throws -> ReceivedTimetable
}
```

2. Replace `TimetablePassManager` with or refactor it into a `@MainActor @Observable` reconciliation service.
3. Maintain at most one reconciliation task.
4. Coalesce repeated notifications with a short cancellable debounce.
5. Compute projection as a complete replacement from currently installed active timetable passes.
6. Preserve received timestamps only when needed and only by stable serial identity.
7. Remove tombstoned passes before projection calculation.
8. Set:
   - `Defaults[.receivedTimetables]` to the complete active projection.
   - `Defaults[.installedWalletTimetableIDs]` to exactly the installed active IDs.
   - `Defaults[.lastWalletReconciliation]` after successful local reconciliation.
   - `Defaults[.walletRevision]` once per effective projection change, not every scan.
9. Upload only when the effective projection changes or when explicitly forced during account bootstrap.
10. Delete by serial ID, never sender/timestamp.
11. Trigger widget reload, App Shortcut parameter refresh, and Spotlight rebuild after an effective change.
12. Remove infrastructure animations.

### Required server implementation

1. Retain deleted `PassRecord` tombstones after all registrations disappear.
2. Ensure deleted owner-account passes and authored passes both receive:

```text
Status
This timetable has been deleted and will be removed from Wallet.
```

3. Confirm `PassFactory.deletedResponse` preserves serial number and valid authentication behavior long enough for Wallet to fetch the tombstone.
4. Confirm an old `.pkpass` import cannot reactivate a deleted record.
5. Confirm `changedSerials` reports deleted records to every still-registered device.
6. Remove only obsolete `PassRegistration` rows, not the revocation record.

### Verification

- Client iOS build.
- Client macOS build because shared models/services compile there even though Wallet library access is iPhone-scoped.
- Server release build.
- Relevant server tests.
- Manual test: remove an active pass from Wallet and confirm it disappears from Defaults/server projection.
- Manual test: delete an authored timetable, receive the update, and confirm Wallet removes it.
- Manual test: import an old deleted pass and confirm it is rejected or immediately removed.

### Commits

Use separate commits if client and server compile independently:

```text
Retain Wallet pass revocation tombstones
Rebuild received timetables from Wallet state
```

---

## Unit 3: Harden Live Activity client lifecycle — completed

### Goal

Ensure Live Activity authorization, push-to-start tokens, update tokens, existing activities, settings changes, sign-out, and relaunch all converge on one correct state.

### Primary files

- `Main/Backend/LiveActivityRegistrationService.swift`
- `Main/Backend/NotificationRegistrationService.swift`
- `Main/TimetableApp.swift`
- `Shared/Models/AccountSettings.swift`
- `Widget/Widget Shared/Live Activity/SchoolDayActivityAttributes.swift`
- `Widget/Widget Shared/Live Activity/SchoolDayLiveActivityWidget.swift`

### Implemented

The service now:

- Observes Activity authorization changes.
- Observes push-to-start token rotation.
- Observes new Activity instances.
- Uploads current and rotating update tokens.
- Discovers existing activities on reconciliation.
- Removes the server token when authorization/settings/authentication disallow activities.
- Requests reconciliation of the current activity.

### Verification

1. Observes `activityStateUpdates` for every discovered activity.
2. Cancels and removes token observers when an activity ends or is dismissed.
3. Reconciles existing activities and their current update tokens before requesting a new activity.
4. Ensure only one current-activity reconciliation request runs at a time.
5. Add bounded retry for token uploads after transient network failure.
6. Do not retry authentication failures indefinitely.
7. When Live Activities are disabled:
   - Stop observers.
   - Remove push-to-start token server-side.
   - Ask the server to end active activities, or call the existing settings path that performs this action.
8. When the user signs out:
   - Remove server token while authentication is still valid.
   - End or invalidate active activities.
   - Then clear credentials.
9. When authorization becomes enabled again, restart all observers and upload current tokens.
10. The Live Activity UI handles `context.isStale` with a restrained “Updating” state.
11. Keep `ContentState` compact and exactly aligned with server JSON keys.
12. Do not add app-driven per-second timers; system timer/progress views must drive countdown rendering.

### Verification

- Xcode validation pending.
- Manual physical-device test for push-to-start and token rotation.
- Manual setting-disable test.
- Manual sign-out test.
- Manual relaunch with an existing active Live Activity.

### Commit

```text
Harden Live Activity client lifecycle
```

---

## Unit 4: Harden Live Activity server scheduling and APNs failure handling — completed

### Goal

Make every school-day start/update/end transition idempotent, recoverable, and correctly cleaned up when tokens become invalid or settings change.

### Primary files

- `Sources/pmstt/Services/LiveActivities/SchoolDayActivityProjector.swift`
- `Sources/pmstt/Services/LiveActivities/SchoolDayActivityScheduler.swift`
- `Sources/pmstt/Services/LiveActivities/SchoolDayActivityCoordinator.swift`
- `Sources/pmstt/Services/LiveActivities/LiveActivityAPNSService.swift`
- `Sources/pmstt/Services/LiveActivities/LiveActivityPayloads.swift`
- `Sources/pmstt/Controllers/LiveActivityController.swift`
- `Sources/pmstt/Models/SchoolDayLiveActivity.swift`
- `Sources/pmstt/Models/SchoolDayLiveActivityTransition.swift`
- Relevant tests under `Tests/pmsttTests`

### Preserve existing work

The uncommitted optional-`next` projector change belongs in this unit. Do not discard it.

### Implemented

1. Validate the projector for:
   - Before school.
   - Lesson.
   - Free period.
   - Recess.
   - Lunch.
   - Final period with `next == nil` or the agreed final label.
   - Finished day.
   - Wednesday/Friday early finish.
   - Weekend, holiday, and term-boundary exclusion.
2. Confirm projector JSON matches `SchoolDayActivityAttributes.ContentState` exactly.
3. Ensure transition claims remain unique and are deleted only when APNs delivery genuinely failed and retry is appropriate.
4. Distinguish transient APNs failures from permanent token invalidation.
5. Clear permanently invalid push-to-start tokens from `UserDevice`.
6. Clear permanently invalid update tokens from `SchoolDayLiveActivity`.
7. Mark ended activities ended even if APNs says the token is permanently invalid.
8. Prevent creation of duplicate active records for one device/school date.
9. Reconciliation must return false when an equivalent active activity already exists.
10. Settings disable and account deletion must end all active records.
11. Scheduler shutdown must cancel its task cleanly.
12. Add structured request/activity/device metadata without logging full tokens.

### Verification

- Scheduler now marks active records ended when settings are disabled.
- Permanently invalid update tokens clear the token and end the activity record.
- Transition claims remain retryable after delivery failures, while successful transitions remain idempotent.
- Validation pending: `swift build -c release`, relevant tests, and the client Xcode gate.

### Commit

```text
Harden school day Live Activity delivery
```

Deploy only if explicitly requested:

```sh
git push production
```

---

## Unit 5: Legacy architecture cleanup — completed

### Goal

Remove superseded code only after Spotlight, Wallet, and Live Activity work builds and behaves correctly.

### Audit result

The audit found no superseded school-state implementation, observable-object architecture, CloudKit timetable synchronization, client pass signing, or duplicate `PKPassLibrary` consumers. WatchConnectivity remains limited to paired-iPhone authentication and account-state messages. The retained `FriendsTimeLeftWidget` is the approved Friends' Current Subjects widget, not the removed standalone Time Left widget.

The specific correctness checks remain satisfied: `SchoolStateEngine` is the active state engine, owner data is included in the timetable and subject queries, and no legacy timetable payload is sent through WatchConnectivity. No speculative deletions were made.

Commands reviewed:

```sh
rg -n 'ObservableObject|StateObject|ObservedObject|EnvironmentObject' . --glob '*.swift'
rg -n 'PKPassLibrary' . --glob '*.swift'
rg -n 'getSchoolState|inClass|inBreak|outsideSchool' . --glob '*.swift'
rg -n 'Date\(\)|Date\.now|\.now' Shared Main Watch Widget 'App Intents' --glob '*.swift'
rg -n 'CloudKit|CKContainer|NSUbiquitous|identifierForVendor|deviceIdentifier' . --glob '*.swift'
rg -n 'WCSession|WatchConnectivity' . --glob '*.swift'
rg -n 'signDataWithBundleKey|generatePass|PKPass' . --glob '*.swift'
```

### Removal rules

1. Remove obsolete school-state helpers. `SchoolStateEngine` is the only school-state implementation.
2. Remove duplicate current-subject calculations from views.
3. Remove any widget/provider that reads Wallet or performs state calculation in `body`.
4. Remove old WatchConnectivity timetable payload keys and handlers. Preserve only credentials and account-state messages.
5. Remove client-side pass signing/generation code if any remains in the client target.
6. Remove CloudKit timetable synchronization remnants.
7. Remove device-identifier-derived identity. Preserve server-issued IDs and Defaults installation ID.
8. Remove obsolete pass-manager UI state once Wallet reconciliation owns the projection.
9. Remove dead Defaults keys only after proving there are no consumers.
10. Remove dead localized strings and project references created by deleted widgets/services.
11. Do not remove compatibility decoding for persisted models unless the data is newly introduced and has no deployed legacy shape.
12. Do not perform unrelated UI redesign.

### Specific correctness audit

- Ensure `TimetableLayout.subjectLookup` remains the only slot-to-subject map builder.
- Ensure Wednesday and Friday cannot show a sixth period.
- Ensure `SubjectQuery` and `TimetableQuery` include owner data where the intent contract expects it.
- Deduplicate subject entities returned from multiple received timetables when an intent asks for generic subjects.
- Ensure App Shortcut dynamic parameters update after received timetable changes.
- Ensure all icon-only controls have accessibility labels.
- Replace tappable `onTapGesture` usage with `Button` where tap position/count is not required.

### Verification

- `git diff --check` passed.
- Unit 5 source audit completed without source removals.
- Xcode validation pending.

### Commit

```text
Remove superseded timetable architecture
```

---

## Unit 6: Final scheme and device verification

### Goal

Prove the supported product surfaces work together without visionOS.

### Command-line gates

1. Timetable generic iOS Debug build.
2. Timetable generic macOS Debug build.
3. Widget generic iOS Debug build.
4. Diagnose and repair standalone Watch scheme command-line product resolution if it still fails.
5. Watch Widget scheme build after Watch scheme repair.
6. pmstt release build.
7. Relevant pmstt tests.

### Standalone Watch scheme diagnosis

The known failure references missing iPhoneOS `MaterialView.o` products while building the Watch scheme. Inspect:

- Scheme build-action target order.
- Whether the Timetable companion target is unnecessarily included for a generic watchOS destination.
- Package product platform filters.
- Derived-data product paths.
- Whether Watch should build through a paired iOS destination instead of generic watchOS.

Do not “fix” this by deleting the Mac or iPhone app dependency blindly.

### Manual iPhone checks

- Owner timetable works signed out.
- Sign in restores account and bootstrap state.
- Owner timetable sync works both directions.
- Received Wallet projection is complete replacement.
- Removing a Wallet pass removes it from Defaults and server projection.
- Deleted/tombstoned pass removes itself.
- Weekly widget defaults to owner.
- Weekly widget can select a received person.
- Next Break widget shows recess/lunch and handles after-school state.
- Friends widget placeholder and real content render correctly.
- Siri Current Subject, Next Subject, Next Break, Subjects for Day, and Timetable for Person resolve correctly.
- Spotlight owner, received, and subject results open the correct destination.
- Live Activity starts, updates at transitions, handles final period, and ends.
- Disabling Live Activities ends the current activity.
- Signing out clears server registration and activity state.

### Manual watch checks

- Watch provisions from paired authenticated iPhone.
- Watch shows “Sign in on iPhone” without a valid provisioned session.
- Watch downloads timetable data directly from the server.
- Watch never receives timetable payloads through WatchConnectivity.
- Current Subject, received timetable pages, progress backgrounds, and watch widgets use the unified state engine.
- Wednesday/Friday early finish is correct.

### Manual macOS checks

- Owner and received timetable projections load from Defaults/server.
- Subject editor symbol fallback compiles and works.
- Spotlight results open the Timetable tab.
- No iOS launch storyboard is compiled into the Mac target.

### Final commit policy

Do not create a catch-all “fix everything” commit. Any issue found in final verification gets its own smallest behavior-scoped commit and must pass its affected build gate.

## Final acceptance criteria

- visionOS remains unsupported and untouched.
- No legacy global school-state implementation exists.
- All timetable-sensitive current-time calculations use `TimetableClock`.
- Widgets are limited to the approved useful set.
- Every timeline widget has representative placeholders.
- Weekly timetable configuration defaults to the owner and supports received people.
- No School Day Progress or Shared Free Period widget/intent is added.
- App Intents resolve owner and received data correctly.
- Siri shortcut phrases include the application-name token.
- Spotlight has stable identifiers, metadata, tombstone removal, and working deep links.
- Only Wallet infrastructure calls `PKPassLibrary`.
- Wallet state becomes a complete replacement received projection on iPhone.
- Removed Wallet passes cannot persist through merge behavior.
- Deleted pass records remain revocation tombstones server-side.
- Old deleted `.pkpass` files cannot reactivate.
- Watch authentication remains paired-iPhone provisioned.
- WatchConnectivity carries credentials/account state, never timetable payloads.
- Live Activity token rotations are observed for push-to-start and update tokens.
- Invalid APNs tokens are removed.
- Live Activity transition delivery is idempotent.
- Disabling Live Activities and signing out end active activities.
- iOS and macOS client builds pass with `xcodebuild`.
- Watch and Watch Widget compile through the supported dependency/build path.
- pmstt release build passes.
- No unrelated dirty changes are discarded.
- Every completed implementation unit has its own commit.
