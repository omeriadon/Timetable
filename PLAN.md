# Timetable Rebuild Implementation Plan

## Architecture Rules

- SwiftUI views, widgets, App Intents, Spotlight, and snippets read persistent timetable/account data only through `Defaults`.
- Only Wallet infrastructure may instantiate or call `PKPassLibrary`.
- Wallet infrastructure reconciles Wallet state into `Defaults`; presentation code never reads Wallet.
- Views use `@Default(.key)` for the smallest required state.
- No `ObservableObject`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject`.
- Shared mutable service state uses `@MainActor @Observable`.
- Services are passed only when a view executes commands or displays transient progress/errors.
- Existing UI designs remain unchanged.
- Existing folder structure remains; focused subfolders may be added.
- No legacy data migrations. Old implementations may be removed once their replacements build.
- Every change is an atomic commit.
- Every commit requires a successful Xcode MCP build before further work.
- Every new Fluent model requires explicit field approval before implementation.

## Source-of-Truth Rules

### Owner timetable

- `Defaults[.timetable]` is the immediate local owner timetable.
- It works without an account and without Wallet.
- Once authenticated, the server stores and synchronizes it.
- The owner Wallet pass is optional.
- Owner-pass presence never controls app data.

### Received timetables

On iOS:

1. Wallet infrastructure reads `PKPassLibrary`.
2. It parses all timetable passes.
3. It removes deleted passes.
4. It writes the complete resulting list to `Defaults[.receivedTimetables]`.
5. It uploads that projection to the server.

On macOS and visionOS:

1. The app downloads the received-timetable projection from the server.
2. It writes the result to `Defaults[.receivedTimetables]`.
3. All UI and extensions read that key.

On watchOS:

1. Authentication state and credentials originate from the paired iPhone.
2. The watch always downloads timetable data from the server.
3. WatchConnectivity distributes credentials and account-state changes, not timetable data.
4. The watch never independently chooses between Wallet, phone data, and server data.

## Received Timetable Model

```swift
struct ReceivedTimetable: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let issuerAccountID: String
    let sourceKind: SourceKind
    let signedDisplayName: String
    let authorDisplayName: String?
    let subjects: [Subject]
    let receivedAt: Date
    let passUpdatedAt: Date
    let isDeleted: Bool
}
```

```swift
enum SourceKind: String, Codable, Hashable, Sendable {
    case accountOwner
    case authoredForThirdParty
}
```

Identity rules:

- All account identifiers are represented as `String` in shared DTOs.
- Server UUIDs are converted with `uuid.uuidString`.
- For `.accountOwner`, `id == issuerAccountID`.
- For `.authoredForThirdParty`, `id` is the server-generated pass serial number.
- `id` is always the pass serial number presented to Wallet.
- Name overrides do not modify `signedDisplayName`.

## Deleted Pass Protocol

Every pass payload contains:

```swift
let isDeleted: Bool
```

Every local `ReceivedTimetable` also contains `isDeleted`.

When an account or authored timetable is deleted:

1. Server marks every corresponding pass record `isDeleted = true`.
2. Server regenerates the pass.
3. The first back field is inserted as:

```text
Status
This timetable has been deleted and will be removed from Wallet.
```

4. Server sends PassKit update pushes to every registration.
5. Wallet downloads the updated pass.
6. `PKPassLibraryDidChange` triggers reconciliation.
7. Reconciliation detects `isDeleted == true`.
8. Wallet infrastructure calls `PKPassLibrary.removePass(_:)`.
9. The deleted timetable is excluded from `Defaults[.receivedTimetables]`.
10. The updated projection is uploaded to the account server.
11. macOS, visionOS, widgets, intents, snippets, and Spotlight remove it during their next Defaults refresh.

Startup reconciliation also deletes any previously downloaded tombstoned passes.

Server records retain a revocation tombstone so an old `.pkpass` cannot be reimported as active.

Functions:

```swift
func deleteTombstonedPasses() async
func removePass(_ pass: PKPass) async
func isPassRevoked(serialNumber: String) async throws -> Bool
func revokePass(serialNumber: String, on database: Database) async throws
```

## Defaults

```swift
extension Defaults.Keys {
    static let timetable: Key<[Subject]>
    static let receivedTimetables: Key<[ReceivedTimetable]>
    static let accountProfile: Key<AccountProfile?>
    static let userDisplayName: Key<String>
    static let receivedNameOverrides: Key<[String: String]>
    static let walletRevision: Key<Int>
    static let lastWalletReconciliation: Key<Date?>
    static let lastServerSync: Key<Date?>
    static let hasCompletedAccountBootstrap: Key<Bool>
    static let accountSettings: Key<AccountSettings>
    static let installationID: Key<String>
}
```

Transient credentials remain in Keychain.

Views use direct declarations:

```swift
@Default(.timetable) private var timetable
@Default(.receivedTimetables) private var receivedTimetables
@Default(.receivedNameOverrides) private var nameOverrides
@Default(.accountSettings) private var accountSettings
```

Functions whose input already exists in Defaults read it internally:

```swift
func currentOwnerSchoolState() -> SchoolState
func currentReceivedSchoolStates() -> [ReceivedSchoolState]
func rebuildSpotlightIndex() async
func makeFriendsWidgetEntry(at date: Date) -> FriendsTimetableEntry
func uploadOwnerTimetable() async throws
```

Do not pass `Defaults[.timetable]`, `Defaults[.receivedTimetables]`, profile, settings, or overrides through view hierarchies.

Pure internal overloads may accept explicit values for tests:

```swift
static func calculate(
    at date: Date,
    subjects: [Subject],
    schedule: SchoolSchedule
) -> SchoolState
```

## Name Overrides

```swift
func receivedDisplayName(for serialNumber: String) -> String {
    if let override = Defaults[.receivedNameOverrides][serialNumber],
       !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return override
    }

    return Defaults[.receivedTimetables]
        .first(where: { $0.id == serialNumber })?
        .signedDisplayName ?? ""
}
```

Commands:

```swift
func setReceivedNameOverride(
    serialNumber: String,
    displayName: String
) async throws

func removeReceivedNameOverride(
    serialNumber: String
) async throws
```

The override editor displays both:

- Current local override.
- Signed account/pass display name.

Removing the override immediately restores the signed name.

## Account Settings

Use one syncable settings value instead of many unrelated Defaults keys:

```swift
struct AccountSettings: Codable, Hashable, Sendable {
    var liveActivitiesEnabled: Bool
    var liveActivityStartTime: TimeOfDay
    var liveActivityEndTime: TimeOfDay
    var liveActivityWeekdays: Set<SchoolWeekday>
    var showBreaksInLiveActivity: Bool
    var showNextSubjectInLiveActivity: Bool
    var widgetShowsReceivedTimetables: Bool
    var spotlightIndexingEnabled: Bool
    var siriAccessEnabled: Bool
}
```

Defaults:

- Live Activities enabled.
- Start at 08:00.
- End at 15:40.
- Monday through Friday.
- Breaks and next subject visible.
- Received timetable widget data enabled.
- Spotlight and Siri enabled.

Settings UI reads:

```swift
@Default(.accountSettings) private var settings
```

Add a dedicated “Account and Sync” settings subsection when the existing settings screen becomes crowded.

Every settings mutation:

1. Updates Defaults immediately.
2. Reloads affected widgets or indexes.
3. Synchronizes the complete settings struct to the server.
4. Reverts only when the server rejects invalid data.
5. Remains locally queued when the network disappears after mutation.

## Server Foundation

Use `moneyServer` as the structural base:

```text
Sources/pmstt/
  Controllers/
  DTOs/
  Functions/
  Migrations/
  Models/
    Types/
  Services/
    Authentication/
    LiveActivities/
    Passes/
  configure.swift
  routes.swift
```

Use its established patterns for:

- Fluent models.
- PostgreSQL configuration.
- migrations.
- route collections.
- DTO validation.
- Bcrypt password hashing.
- token authenticators.
- authenticated route groups.
- account deletion.
- profile updates.

Improve its security model by storing refresh-token hashes rather than plaintext tokens.

Do not force periodic interactive sign-in. Sessions use:

- Short-lived access token.
- Long-lived rotating refresh token.
- Silent refresh.
- Refresh-token invalidation only on logout, account deletion, credential reset, explicit server revocation, or suspected compromise.

## Server Models

Each model receives a separate approval, implementation, build, test, and commit cycle.

### `User`

```swift
id: UUID
email: String?
passwordHash: String?
appleSubject: String?
displayName: String
selfPassSerialNumber: String
settingsData: Data
createdAt: Date
updatedAt: Date
```

### `UserToken`

```swift
id: UUID
tokenHash: String
userID: UUID
expiresAt: Date
createdAt: Date
lastUsedAt: Date?
```

### `OwnerTimetable`

```swift
id: UUID
userID: UUID
subjectsData: Data
revision: Int
createdAt: Date
updatedAt: Date
```

### `AuthoredTimetable`

```swift
id: UUID
authorUserID: UUID
subjectDisplayName: String
passSerialNumber: String
subjectsData: Data
revision: Int
isDeleted: Bool
createdAt: Date
updatedAt: Date
```

### `ReceivedPassMirror`

```swift
id: UUID
userID: UUID
passSerialNumber: String
issuerAccountID: String
sourceKind: String
signedDisplayName: String
authorDisplayName: String?
subjectsData: Data
isDeleted: Bool
walletRevision: Int
receivedAt: Date
passUpdatedAt: Date
updatedAt: Date
```

### `ReceivedNameOverride`

```swift
id: UUID
userID: UUID
passSerialNumber: String
displayName: String
createdAt: Date
updatedAt: Date
```

### `UserDevice`

```swift
id: UUID
userID: UUID
installationID: String
platform: String
apnsToken: String?
liveActivityPushToStartToken: String?
lastSeenAt: Date
createdAt: Date
updatedAt: Date
```

### `PassRegistration`

```swift
id: UUID
deviceLibraryIdentifier: String
passTypeIdentifier: String
serialNumber: String
pushToken: String
createdAt: Date
updatedAt: Date
```

### `PassRecord`

```swift
id: UUID
serialNumber: String
issuerAccountID: String
sourceKind: String
authoredTimetableID: UUID?
revision: Int
authenticationTokenHash: String
isDeleted: Bool
createdAt: Date
updatedAt: Date
```

## NetworkManager

Keep client networking in one organized file:

```text
Shared/Networking/NetworkManager.swift
```

Use `// MARK: -` sections:

```swift
// MARK: - State
// MARK: - Reachability
// MARK: - Authentication
// MARK: - Request Construction
// MARK: - Request Execution
// MARK: - Response Validation
// MARK: - Decoding
// MARK: - Uploads
// MARK: - Downloads
// MARK: - Error Presentation
// MARK: - Logging
```

```swift
@MainActor
@Observable
final class NetworkManager {
    static let shared = NetworkManager()

    private(set) var isOnline: Bool
    var presentedAlert: NetworkAlert?

    func startMonitoring()
    func requireOnline() throws
    func send<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        body: (some Encodable & Sendable)?
    ) async throws -> Response
    func send(_ endpoint: Endpoint) async throws
    func download(_ endpoint: Endpoint) async throws -> Data
    func upload<Response: Decodable & Sendable>(
        _ endpoint: Endpoint,
        body: some Encodable & Sendable
    ) async throws -> Response
    func present(_ error: Error)
}
```

Before any request:

```swift
guard isOnline else {
    presentedAlert = .offline
    throw NetworkError.offline
}
```

No URL request is created or resumed while known offline.

The root content view owns the transient alert presentation:

```swift
@State private var networkManager = NetworkManager.shared
```

```swift
.alert(item: $networkManager.presentedAlert) { alert in
    Alert(
        title: Text(alert.title),
        message: Text(alert.message),
        dismissButton: .default(Text("OK"))
    )
}
```

Server errors use stable codes:

```swift
struct ServerErrorResponse: Codable, Sendable {
    let code: ServerErrorCode
    let message: String
    let field: String?
    let requestID: String
}
```

Examples:

```swift
enum ServerErrorCode: String, Codable, Sendable {
    case offline
    case invalidCredentials
    case emailAlreadyExists
    case invalidAppleIdentityToken
    case sessionExpired
    case accountNotFound
    case timetableConflict
    case invalidTimetable
    case passGenerationFailed
    case passRevoked
    case liveActivityDisabled
    case rateLimited
    case internalServerError
}
```

RapidAPI testing is supported by:

- Stable JSON request/response DTOs.
- Bearer-token authentication.
- Predictable status codes.
- Human-readable messages.
- Machine-readable error codes.
- Request IDs.
- A complete endpoint test collection documented beside the server.

## Authentication and Watch

`SessionStore` is `@MainActor @Observable`, not an environment object.

```swift
@MainActor
@Observable
final class SessionStore {
    static let shared = SessionStore()

    private(set) var state: AuthenticationState

    func restore() async
    func signUp(email: String, password: String, displayName: String) async throws
    func signIn(email: String, password: String) async throws
    func signInWithApple(_ authorization: ASAuthorization) async throws
    func refreshSilently() async throws
    func signOut() async
    func deleteAccount() async throws
}
```

Watch behavior:

- The phone sends the active session material to the paired watch through WatchConnectivity.
- The watch stores it in its own Keychain.
- The watch uses `NetworkManager` to call the server directly.
- The phone sends logout, token rotation, and account deletion events to the watch.
- The watch does not expose independent signup or login.
- If the watch loses a valid session, it displays a “Sign in on iPhone” state.
- Timetable payloads are never synchronized through WatchConnectivity.

## Wallet Infrastructure

```swift
struct WalletTimetableReader {
    func timetablePasses() -> [PKPass]
    func decode(_ pass: PKPass) throws -> ReceivedTimetable
}
```

```swift
@MainActor
@Observable
final class WalletReconciliationService {
    static let shared = WalletReconciliationService()

    private(set) var isReconciling: Bool

    func startObserving()
    func stopObserving()
    func reconcile() async
    func deleteTombstonedPasses() async
    func uploadCurrentProjection() async
}
```

Only these files import PassKit for library access.

UI command services may request pass data from the server and present the system add-pass controller, but views never query the pass library.

Reconciliation coalesces repeated Wallet notifications to avoid duplicate parsing and network calls.

## Logging

Extend the existing logging utilities:

```swift
enum LogCategory: String {
    case account
    case network
    case wallet
    case defaults
    case widget
    case intents
    case spotlight
    case liveActivity
    case watch
    case server
    case database
    case passes
}
```

```swift
func Print(
    _ message: @autoclosure () -> String,
    category: LogCategory,
    function: StaticString = #function
)

func PrintError(
    _ message: @autoclosure () -> String,
    category: LogCategory,
    function: StaticString = #function,
    error: Error? = nil
)
```

Instrument:

- Function entry for service, controller, route, reconciliation, persistence, token, Wallet, and synchronization functions.
- Success with duration and non-sensitive identifiers.
- Every caught error.
- Every skipped operation and reason.
- Every state transition.
- Every server request with request ID and status.
- Database mutations without private payloads.
- Pass-generation stages.
- Live Activity scheduling and APNs results.

Do not print:

- Passwords.
- access tokens.
- refresh tokens.
- Apple identity tokens.
- APNs tokens in full.
- pass authentication tokens.
- raw timetable JSON in production.

Hot calculation and SwiftUI rendering functions use debug-only or rate-limited logs. Unconditional logging inside widget bodies, timers, collection loops, or school-state calculations would violate the performance requirement.

## School-State Refactor

Use an enum namespace:

```swift
enum SchoolStateEngine {
    static func currentOwnerState() -> SchoolState
    static func currentReceivedStates() -> [ReceivedSchoolState]
    static func state(forReceivedTimetableID id: String) -> SchoolState
    static func timelineTransitions(forReceivedTimetableID id: String) -> [Date]

    static func calculate(
        at date: Date,
        subjects: [Subject],
        schedule: SchoolSchedule
    ) -> SchoolState
}
```

Defaults-facing functions read Defaults internally. The explicit calculation function exists for deterministic tests.

Typed models:

```swift
struct TimeOfDay: Codable, Hashable, Sendable {
    let hour: Int
    let minute: Int

    init(_ hour: Int, _ minute: Int) {
        self.hour = hour
        self.minute = minute
    }
}
```

```swift
struct SchoolPeriod: Codable, Hashable, Sendable {
    let number: Int
    let start: TimeOfDay
    let end: TimeOfDay

    init(_ number: Int, _ start: TimeOfDay, _ end: TimeOfDay) {
        self.number = number
        self.start = start
        self.end = end
    }
}
```

Retain simple unlabeled initializers for `Slot` and similar compact value types.

`SchoolState` removes unsafe optionals:

```swift
enum SchoolState: Hashable, Sendable {
    case beforeSchool(next: ScheduledSubject)
    case lesson(CurrentLesson)
    case freePeriod(CurrentFreePeriod)
    case recess(BreakState)
    case lunch(BreakState)
    case afterSchool
    case weekend
    case noTimetable
}
```

Every current-time access uses:

```swift
enum TimetableClock {
    static var now: Date {
        Date().addingTimeInterval(debugOffset)
    }
}
```

No timetable-sensitive code directly calls `Date()`, `.now`, or `Date.now`.

## Widgets and Snippets

Providers read Defaults and create complete entries.

Views render entries only.

Remove from widget views:

- `PKPassLibrary`.
- `TimetablePassManager`.
- `NetworkManager`.
- Defaults reads.
- school-state calculation.
- current-date calculation.
- device identifiers.

Functions:

```swift
enum WidgetEntryFactory {
    static func ownerEntry() -> TimetableEntry
    static func friendsEntry() -> FriendsTimetableEntry
    static func weeklyEntry() -> WeeklyScheduleEntry
}
```

Timer displays use WidgetKit-compatible timer rendering:

```swift
Text(timerInterval: start...end, countsDown: true)
```

Do not drive widget timers with app timers or scheduled tasks.

Apply fixed Dynamic Type behavior to layout-sensitive widgets and snippet views:

```swift
.dynamicTypeSize(.medium)
```

Preserve the existing widget designs. New widgets may be added only with separate types and designs.

Potential additions:

- Next lesson.
- Today’s lesson sequence.
- Selected person’s current lesson.
- Shared free period.
- Tomorrow’s first lesson.
- School-day progress.

## App Intents and Siri

Add complete entity/query coverage:

```swift
TimetableEntity
SubjectEntity
SchoolDayEntity
PersonTimetableEntity
```

```swift
TimetableQuery
SubjectQuery
SchoolDayQuery
PersonTimetableQuery
```

Intents:

```swift
GetCurrentSubjectIntent
GetNextSubjectIntent
GetReceivedTimetablesIntent
GetTimetableForPersonIntent
GetSubjectsForDayIntent
GetNextBreakIntent
GetSchoolDayProgressIntent
FindSharedFreePeriodIntent
```

All queries read Defaults internally.

Snippet views:

- Use `.dynamicTypeSize(.medium)`.
- Receive fully prepared intent results.
- Never query Wallet or the network.
- Use stable fixed-height layouts.
- Avoid optional-driven layout changes.

## Spotlight

```swift
actor SpotlightIndexer {
    static let shared = SpotlightIndexer()

    func rebuildFromDefaults() async
    func indexOwnerTimetable() async
    func indexReceivedTimetables() async
    func removeDeletedTimetables() async
    func removeAll() async
}
```

`rebuildFromDefaults()` reads Defaults internally.

Index:

- Owner timetable.
- Every active received timetable.
- Every subject.
- Current signed or overridden display name.
- Source kind.
- Deep-link identifiers.

Trigger indexing after Defaults mutations, not after Wallet events directly.

When indexing is disabled:

1. Remove all existing app indexes.
2. Stop future indexing.
3. Preserve local timetable data.

## Live Activities

Complete the existing server APNs work and add missing client support.

Settings are read from `Defaults[.accountSettings]`.

Client functions:

```swift
func observeLiveActivityPushToStartToken() async
func uploadLiveActivityPushToStartToken(_ token: Data) async
func removeLiveActivityToken() async
func reconcileLiveActivityAuthorization() async
```

Server functions:

```swift
func startSchoolDayActivities(at date: Date) async
func updateSchoolDayActivities(at date: Date) async
func endSchoolDayActivities(at date: Date) async
func sendLiveActivityPush(
    to token: String,
    event: LiveActivityEvent
) async throws
```

Rules:

- Disabled accounts receive no starts.
- Existing activities are ended when the setting is turned off.
- Start and end times come from account settings.
- Default schedule remains weekdays from 08:00 to 15:40.
- Updates occur at typed school-state transitions.
- Invalid APNs tokens are removed.
- Jobs are idempotent.
- Push-to-start token rotation replaces the previous token.
- Server token persistence uses PostgreSQL, never JSON files.

## Performance Requirements

Before every commit:

- Inspect new `.onAppear`, `.task`, notification observers, Defaults observations, and repeated computations.
- Move startup work to one root `.task`.
- Ensure `.task` operations are cancellable.
- Coalesce Wallet and Defaults-triggered refreshes.
- Do not perform network, pass parsing, Spotlight indexing, or expensive mapping inside `body`.
- Precompute widget entries in providers.
- Keep logging out of hot rendering loops.
- Measure pass parsing and large Defaults encoding with `ContinuousClock`.
- Reject changes that introduce visible main-thread stalls.
- Use `@concurrent` only for proven CPU-heavy encoding, hashing, ZIP, or indexing preparation.
- Use no `DispatchQueue`, semaphores, or detached tasks.

## Immediate Timeline

### Step 1: Establish build baselines

- Inspect git state in Timetable, `pmstt`, and `moneyServer`.
- Build every existing Timetable scheme through Xcode MCP.
- Build `pmstt`.
- Build `moneyServer`.
- Record existing warnings and failures.
- Make no commit.

Stop until all baseline failures are understood.

### Step 2: Replace the planning document

- Replace the existing architecture document with this specification.
- Commit only the document.

Build gate: none for documentation.

Commit:

```text
Document account and Wallet rebuild architecture
```

### Step 3: Refactor logging utilities

- Extend `Print` and `PrintError`.
- Add categories, function names, durations, and redaction.
- Adopt them in new code only; avoid a project-wide logging rewrite.

Build gate: all Timetable schemes.

Commit:

```text
Add structured client diagnostic logging
```

### Step 4: Create server infrastructure

- Add Fluent and PostgreSQL.
- Copy the clean configuration structure from `moneyServer`.
- Add structured server errors and request IDs.
- Replace file-based Live Activity token storage.
- Add health and error-response tests.

Build gate: `pmstt`.

Commit:

```text
Configure persistent timetable server foundation
```

### Step 5: Approve and add `User`

Before editing:

- Present the exact `User` model.
- Confirm nullable email/password behavior for Apple-only users.
- Confirm settings storage.
- Confirm deletion relationships.

Then implement model, migration, DTOs, and tests.

Build gate: `pmstt`.

Commit:

```text
Add timetable account user model
```

### Step 6: Approve and add `UserToken`

- Present exact token fields and expiration policy.
- Implement access and refresh token behavior based on `moneyServer`.
- Add silent refresh and revocation tests.

Build gate: `pmstt`.

Commit:

```text
Add secure persistent account sessions
```

### Step 7: Implement authentication routes

- Email signup.
- Email login.
- Sign in with Apple.
- refresh.
- logout.
- profile fetch/update.
- structured errors.

Build gate: `pmstt`.

Commits:

```text
Add email account authentication
Add Sign in with Apple authentication
Add account profile endpoints
```

### Step 8: Add client `NetworkManager`

- Add reachability.
- Prevent known-offline calls.
- Add server-error decoding.
- Add silent token refresh.
- Add top-level alert presentation.
- Add logging and tests.

Build gate: every Timetable scheme.

Commits:

```text
Add centralized account NetworkManager
Present network failures from the app root
```

### Step 9: Add client session state

- Keychain credentials.
- Defaults account profile.
- email/password flows.
- Sign in with Apple flow.
- phone-to-watch credential distribution.

Build gate: iOS, macOS, visionOS, and watchOS.

Commit:

```text
Add synchronized account session state
```

### Step 10: Continue model-by-model

Proceed separately through:

1. `OwnerTimetable`
2. `AuthoredTimetable`
3. `PassRecord`
4. `PassRegistration`
5. `ReceivedPassMirror`
6. `ReceivedNameOverride`
7. `UserDevice`

Each model has:

1. Field approval.
2. One model/migration commit.
3. Xcode MCP server build.
4. Model tests.
5. No work on the next model before success.

## Later Execution Order

1. Server timetable APIs.
2. Server pass generation.
3. PassKit web service.
4. Client Defaults model replacement.
5. Wallet parsing and tombstone deletion.
6. iOS Wallet reconciliation.
7. macOS/visionOS server projection.
8. watch online-only synchronization.
9. account bootstrap progress UI.
10. school-state engine.
11. widget provider refactor.
12. App Intents and snippets.
13. Spotlight.
14. Live Activity completion.
15. account deletion.
16. removal of CloudKit, device IDs, client pass signing, old pass manager, and obsolete watch timetable payload sync.
17. full multiplatform build and device verification.

## Atomic Commit Protocol

For every implementation unit:

1. Read `git status`.
2. Limit edits to one behavior.
3. Run focused tests.
4. Build every affected scheme through Xcode MCP.
5. Stop on failure.
6. Repair the same unit.
7. Rebuild.
8. Inspect the diff.
9. Commit only after success.
10. Start the next unit.

No catch-all commits. No mixed server/client commits unless a single protocol cannot compile independently.

## Acceptance Criteria

- No UI, widget, App Intent, snippet, or Spotlight type calls `PKPassLibrary`.
- Persistent UI data is read through `@Default`.
- No `ObservableObject` remains.
- iPhone Wallet state completely determines received timetables.
- macOS, visionOS, and watchOS receive server projections.
- Deleted passes update with a visible deletion back field and then remove themselves during reconciliation.
- `.accountOwner` uses the issuer account ID string as its serial number and local ID.
- Network operations fail before request creation when known offline.
- Server errors carry stable codes and produce app alerts.
- Sessions silently refresh without routine user sign-in.
- Widgets remain entry-driven and use WidgetKit-compatible timers.
- Timetable-sensitive dates always use `debugOffset`.
- Spotlight, Siri, snippets, and widgets read the same Defaults projection.
- Live Activity behavior is controlled by syncable account settings.
- Every server model is approved independently.
- Every atomic change builds successfully through Xcode MCP before further work.
