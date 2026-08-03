# Timetable Main-Platform Merge Plan

Status: planning complete enough to begin implementation after review.

Date: 2026-08-03

## Implementation progress

- Phase 1 complete in source: platform, navigation, capability, target-membership, presentation, and structural boundaries are recorded in `PLATFORM_MERGE_INVENTORY.md`.
- Phase 2 complete in source: shared presentation resolution, generic platform values, adaptive padding, and adaptive frame APIs are implemented.
- Phase 3 complete in source: shared Codable routes, versioned route URLs, legacy timetable URL decoding, and external route producers are implemented.
- Phase 4 complete in source: every app window owns a router with compact paths, sidebar state, inspector state, deferred external routes, presentation translation, and optional persistence.
- User Xcode build and runtime verification remains outstanding. Source inspection does not establish compilation or behavior.

Repositories:

- Client: `/Users/omeriadon/Documents/Xcode_App_Library/Timetable`
- Server: `/Users/omeriadon/Documents/Xcode_App_Library/pmstt`

Companion checklist: `USER_PLATFORM_MERGE_CHECKLIST.md`

## Objective

Merge the iPhone, iPadOS, and native macOS products into one complete main-app product while preserving distinct navigation shells appropriate to each presentation size.

The current iPhone implementation is the visual, behavioral, and feature reference. iPadOS and macOS do not retain their reduced non-authoritative implementations. Their existing roots are removed and replaced by adaptations of the complete iPhone feature set.

The watch app remains a separate product. It uses shared networking, session, models, settings, and read services where technically possible, but remains non-authoritative and cannot mutate server state. Its interface must not be intentionally redesigned during this project.

## Non-negotiable outcomes

- iPhone retains a bottom tab bar.
- iPhone remains visually and behaviorally equivalent to the current implementation.
- iPadOS uses a native, content-rich, two-column `NavigationSplitView` at regular width.
- Narrow iPad windows use the iPhone compact presentation and iPhone layout values.
- macOS uses the native two-column sidebar architecture derived from regular-width iPadOS.
- macOS supports freely resizable and multiple windows.
- iPhone, iPadOS, and macOS receive the complete main-app feature set.
- Account creation is available on iPhone, iPadOS, and macOS.
- Account, timetable, settings, received timetable, created timetable, sharing, friends, and administration mutations are available on all three main platforms.
- Watch remains provisioned through an iPhone parent session.
- Watch can sign in through provisioning, sign out, and read the data required by its UI.
- Watch cannot mutate account data, timetables, friends, settings, notifications, or other server data.
- The watch Highlight Current Day toggle is removed; the watch only reads the shared setting.
- Existing user records and product data are preserved.
- Existing sessions may be invalidated.
- Client/server backwards compatibility is not required.
- The current custom UIKit root tab controller is removed.
- Native Apple sidebars, toolbars, inspectors, popovers, and navigation are used.
- Current custom visual controls remain unless they become genuinely unused.
- Existing sheet detents and matched transitions are not broadly changed during this project.
- Existing dark appearance, monospaced typography, and Dynamic Type constraints remain.
- Shared resources and asset catalogs live under `Special` where appropriate.
- Physical folders, not organizational-only Xcode groups, define source organization.
- Files are moved separately from substantive behavioral changes where practical.
- Codex does not run builds or tests. The user performs every Xcode and runtime validation gate.
- Every completed atomic behavior step is committed in the repository's lowercase commit style.

## Current architecture and why it must change

The `Timetable` Xcode target already supports `iphoneos`, `iphonesimulator`, and `macosx`. This project does not need another main application target.

The product is divided in source and policy:

- `TimetableApp` chooses different authentication and authenticated roots using platform compilation and iPad runtime checks.
- iPhone enters `ContentView`.
- `ContentView` exists only under `os(iOS)` and embeds a custom UIKit `UITabBarController`.
- iPadOS and macOS enter `NonAuthoritativeRootView`.
- `NonAuthoritativeRootView` exposes only Timetable and reduced Settings tabs.
- Full `SettingsView` exists only under `os(iOS)`.
- `NonAuthoritativeSettingsView` is a reduced copied implementation.
- Several complete feature files have iOS-only Xcode platform membership.
- `Platform` grants authoritative behavior only to `.iOS`.
- Client services actively reject owner, created timetable, received timetable, sharing, and editing operations on iPadOS and macOS.
- pmstt independently maps iPadOS and macOS to non-authoritative sessions.
- pmstt grants iPadOS and macOS only read, logout, and notification mutation capabilities.
- pmstt accepts account creation only from iPhone.
- Watch session validation requires an active iPhone parent session.

Deleting only `NonAuthoritativeRootView` would expose UI that the server rejects. The client and server authority changes are one contract migration.

## Design principles

### iPhone-first expansion

The order for every feature is:

1. Identify the current iPhone behavior.
2. Preserve the iPhone view and interaction contract.
3. Extract navigation-container ownership from the feature.
4. Make the feature content compile for iPadOS and macOS.
5. Add only the presentation adaptations required for sidebar, inspector, popover, window, or framework behavior.
6. Validate iPhone before accepting the expanded implementation.

iPadOS and macOS do not become the new source of truth. Shared code is extracted from the iPhone feature, then hosted in platform-appropriate shells.

### Separate shells, shared destinations

Do not implement one giant root `body` containing pervasive size and platform branches.

Use two explicit shells:

- `CompactAppShell`: iPhone and narrow iPad windows.
- `SidebarAppShell`: regular-width iPad windows and macOS.

Both shells use:

- the same router model;
- the same root destination enum;
- the same feature route enum;
- the same feature views;
- the same services and models;
- the same authentication state;
- the same presentation destination types where meaningful.

Only navigation composition differs.

### Presentation size over physical device

Layout selection uses presentation width, not a permanent `Device.isIPad` decision.

- iPhone uses compact values.
- iPad in compact horizontal presentation uses compact iPhone values.
- iPad in regular horizontal presentation uses iPadOS values.
- macOS uses macOS values, with responsive constraints inside freely resizable windows.
- watchOS does not compile the main-platform layout helper.

### Keep platform code at framework boundaries

Remaining platform branches are acceptable only for genuine boundaries such as:

- UIKit versus AppKit application delegates;
- WatchConnectivity;
- ActivityKit;
- remote-notification registration entry points;
- photo capture or photo-library APIs;
- file import;
- sharing implementation details not covered by shared SwiftUI APIs;
- macOS windows and commands;
- visual-effect representables;
- target entitlements and extension embedding.

Feature availability and business rules must not be hidden in UIKit/AppKit adapters.

## Target architecture

```text
TimetableApp
├── shared scene lifecycle
├── per-window AppRouter
├── authentication state
└── AppSessionRoot
    ├── AuthenticationRoot
    └── AdaptiveMainRoot
        ├── CompactAppShell
        │   └── TabView<MainTab>
        │       ├── Timetable NavigationStack
        │       ├── Friends NavigationStack
        │       ├── Settings NavigationStack
        │       └── Administration NavigationStack
        └── SidebarAppShell
            └── NavigationSplitView
                ├── AppSidebar
                │   ├── account header
                │   ├── current/next class
                │   ├── timetable switchers
                │   ├── primary destinations
                │   ├── received timetables
                │   ├── friends and requests
                │   ├── upcoming events
                │   ├── settings destinations
                │   ├── administration section
                │   ├── creation actions
                │   ├── search
                │   └── sync/account footer
                └── SidebarDetailHost
                    ├── selected feature
                    ├── popovers
                    └── inspector
```

The sidebar is not a restyled tab bar. It is a first-class application surface with persistent and contextual content.

## Router architecture

### Ownership

- Every main app window owns one `@State` router.
- The router is injected through the SwiftUI environment.
- A router is never a process-wide singleton.
- Separate macOS windows never share navigation paths or presentation state.
- Shared model and sync stores may remain process-wide where their semantics are global.

### Router form

Use an `@MainActor @Observable` reference type because navigation changes originate from views, App Intents, URLs, widgets, tutorials, notifications, and session events.

The router owns:

- selected presentation mode;
- selected compact tab;
- one path per compact tab;
- selected sidebar root destination;
- sidebar detail path;
- sidebar visibility;
- active inspector destination;
- externally addressable sheet or popover destination where required;
- pending external route while signed out or restoring;
- restoration state;
- route-to-presentation adaptation.

### Route model

Routes must contain stable, lightweight identifiers rather than view instances.

Proposed hierarchy:

```swift
enum AppRoute: Hashable, Codable, Sendable {
    case root(AppRootDestination)
    case timetable(TimetableRoute)
    case friends(FriendsRoute)
    case settings(SettingsRoute)
    case administration(AdministrationRoute)
    case account(AccountRoute)
    case onboarding(OnboardingRoute)
}
```

Feature enums contain IDs and compact parameters only. Model data is resolved when the destination renders.

Examples:

- timetable owner;
- received timetable UUID;
- subject identifier and slot;
- planner event UUID;
- friend UUID;
- friend requests;
- account profile;
- notification preferences;
- created timetable UUID;
- received timetable management;
- tag subscriptions;
- administration user UUID;
- administration event UUID;
- administration tag UUID;
- administration badge UUID;
- administration server access;
- onboarding page identifier.

### Route consumers

All entry points produce `AppRoute` values or URLs decoded into `AppRoute`:

- in-app buttons and navigation links;
- widgets through `Link` or `widgetURL`;
- App Intents;
- Spotlight entities;
- Universal Links;
- custom fallback URLs;
- Messages extension links;
- tutorials;
- notification taps;
- macOS commands;
- internal account-authority changes.

Widgets do not own the app router. They generate a stable router-compatible URL. The main app decodes it and routes through the per-window router.

### Destination presentation policy

The route identifies content, not a fixed presentation style.

The router maps the same route according to the active shell:

- compact: push through the selected tab's `NavigationStack`;
- regular Settings or Administration detail: prefer inspector or large popover;
- regular friend detail: large popover;
- regular timetable comparison: inspector where practical, otherwise detail replacement;
- confirmation or editing workflow: retain sheet where confirmation or isolated editing is appropriate;
- unavailable inspector width: fall back to push or sheet.

This permits one route to work from any view without teaching every caller about size class.

### Persistence

Add a Settings option controlling whether navigation state persists.

When enabled, persist:

- selected compact tab;
- each compact tab path where routes remain codable and valid;
- selected sidebar root;
- sidebar detail path;
- sidebar visibility;
- optionally the last stable inspector content if restoration is safe.

Do not persist transient confirmation dialogs, destructive actions, unsaved editors, authentication sheets, or security-sensitive form state.

When disabled:

- clear saved navigation state immediately;
- retain only current in-memory navigation until the window closes;
- start future windows at Timetable.

Invalid or deleted identifiers are discarded during restoration without blocking the rest of the path.

## Compact app shell

### Supported presentations

- iPhone.
- iPad in compact horizontal presentation.
- Narrow Stage Manager iPad windows.

### Tab contract

Use SwiftUI `TabView` with enum selection and one independent `NavigationStack` per tab.

Tabs:

1. Timetable
2. Friends
3. Settings
4. Administration, conditional on current authority

The shell must preserve where technically possible:

- current ordering;
- current symbols;
- monospaced tab labels;
- current cross-dissolve between tabs;
- selected-tab behavior;
- authority-based Administration insertion and removal;
- tab reselection behavior;
- notification and deep-link tab selection.

Remove `ProminentActionTabView`, `UITabBarController`, `UITab`, `UITabBarAppearance`, its coordinator, and `TabBarFont` after SwiftUI parity is established.

If SwiftUI does not expose an exact equivalent for a purely cosmetic UIKit tab configuration, preserve the closest native behavior without retaining the entire controller bridge.

### Navigation stacks

Each compact tab owns its own router path:

- `timetablePath`
- `friendsPath`
- `settingsPath`
- `administrationPath`

Do not place new nested `NavigationStack` containers inside feature root views once the shell owns them.

## Sidebar app shell

### Supported presentations

- iPad with regular horizontal presentation.
- macOS.

### Split structure

Use a native two-column `NavigationSplitView`:

- sidebar;
- detail.

Do not add a permanent middle content column. Settings and Administration details use popovers, inspectors, sheets, or compact navigation according to presentation.

Received timetable management may use a nested split view inside the detail surface if native navigation behavior remains stable. Do not nest split views until selection, column visibility, and toolbar behavior are tested conceptually against the outer split view.

### Sidebar sections

The initial section model is:

1. Account header
   - profile photo;
   - display name;
   - account access action.
2. School status
   - current class or next class;
   - time/progress where current iPhone data supports it.
3. Timetables
   - owner timetable;
   - timetable switcher;
   - received timetables;
   - creation/import actions where applicable.
4. Main
   - Timetable;
   - Friends;
   - Settings.
5. Friends
   - directly accessible friend rows or a bounded recent subset;
   - pending request indicator and action.
6. Planner
   - bounded upcoming events;
   - Planner destination.
7. Settings
   - settings category shortcuts.
8. Administration
   - separate section;
   - visible only to administrators;
   - direct tool shortcuts where appropriate.
9. Footer/status
   - sync status;
   - account control;
   - server state where useful.

The sidebar supports:

- native scrolling;
- native collapse and expansion;
- persistent visibility;
- search;
- creation actions;
- contextual content based on selection;
- stable root-selection identity.

It does not support disclosure-group navigation as a primary structure.

It does not become a custom-drawn sidebar.

### Contextual sidebar content

Context changes must not replace the entire sidebar identity or destroy selection.

Use stable sections with content that updates within them. Examples:

- selected received timetable affects timetable-specific actions;
- selected friend affects a bounded contextual summary;
- selected Settings category affects available inspector actions;
- selected Administration tool affects administrator actions.

Do not make unrelated root destinations disappear during ordinary navigation.

### Inspectors and popovers

On regular-width iPadOS and macOS:

- Settings rows that push on iPhone should open inspector content when the content is suitable for persistent side editing or inspection.
- Administration rows that push on iPhone should open inspector content under the same rule.
- Short viewing content may use a popover.
- Friend details use a large popover initially.
- Timetable comparison prefers an inspector.
- Confirmation and isolated editing flows retain sheets.
- Popovers must have sufficient ideal size for full content without behaving like tiny context menus.
- Inspector presentation state is router-owned.
- Only one primary inspector is active per window.

Use `inspector(isPresented:content:)` and native inspector column sizing where available. Keep a route-to-presentation table so feature views do not decide presentation independently.

## macOS-specific behavior

- Remove fixed 700-point window width.
- Remove content-driven window resizing through `WindowMode` if no remaining feature requires it.
- Remove the custom translucent/material window background.
- Remove `CustomMaterialView` when unused.
- Allow normal free resizing with a sensible minimum content size.
- Support multiple windows.
- Give every window an independent router and presentation namespace.
- Keep mutations synchronized through shared server-backed services.
- Keep Settings inside the main sidebar, not a separate Settings scene.
- `Command-,` selects Settings in the current window.
- Add `Command-1`, `Command-2`, and sequential shortcuts for principal sidebar destinations.
- Use normal macOS menu command presentation so holding Command exposes shortcut hints through the system.
- Use SwiftUI `.toolbar` APIs.
- Keep comparison, inspection, and editing in the current window where practical.
- Provide the full profile photo selection and crop experience through macOS-compatible input adapters.
- Begin sharing with SwiftUI-provided sharing APIs.
- Keep platform-specific AppKit code limited to application lifecycle, notification registration, window coordination, and unavailable SwiftUI gaps.

## iPadOS responsive behavior

The root observes presentation width and changes shell without treating iPad as permanently regular.

Required behavior:

- regular iPad: sidebar shell;
- compact iPad: compact tab shell;
- transition between them without losing the logical route;
- compact layout values on compact iPad;
- iPad layout values on regular iPad;
- inspector routes translate to pushed routes when compact;
- pushed compact routes translate back to appropriate detail or inspector routes when regular;
- unsaved modal editors remain modal across size changes;
- root selection and paths remain stable where their equivalents exist.

The router, not individual features, performs route translation.

## Shared platform-value API

### Availability

The main-platform helpers compile for iOS and macOS, including the shared iOS/macOS Widget target. They do not compile for watchOS or the Watch Widget target.

Use explicit compilation:

```swift
#if !os(watchOS)
// Main-platform layout API.
#endif
```

Target membership must ensure the file is available to the shared widget target without forcing watchOS compilation.

### Presentation model

Define `AppPresentation` as a shared declaration, not through an extension:

```swift
enum AppPresentation: Codable, Hashable, Sendable {
    case compact
    case iPad
    case macOS

    func value<Value>(
        iOS: Value,
        macOS: Value
    ) -> Value {
        switch self {
            case .compact, .iPad:
                iOS
            case .macOS:
                macOS
        }
    }

    func value<Value>(
        iOS: Value,
        iPadOS: Value,
        macOS: Value
    ) -> Value {
        switch self {
            case .compact:
                iOS
            case .iPad:
                iPadOS
            case .macOS:
                macOS
        }
    }
}
```

The two-value overload makes regular iPad inherit the iOS value. Compact iPad always uses iPhone values.

Expose the presentation through an environment value so views and modifiers use the same classification.

The root sets the environment based on:

- compact horizontal presentation on iOS: `.compact`;
- regular horizontal presentation on iPad: `.iPad`;
- macOS: `.macOS`.

Do not use screen bounds. Window and scene presentation control the value.

### Padding overloads

Add external `View` extensions because SwiftUI's `View` declaration is not owned by the project.

Required call forms:

```swift
content
    .padding(iOS: 10, macOS: 24)
```

```swift
content
    .padding(
        .horizontal,
        iOS: 10,
        iPadOS: 18,
        macOS: 24
    )
```

Implement them as dedicated `ViewModifier` types reading `AppPresentation` from the environment. Do not attempt to read environment values from a static global function.

### Frame overloads

Support frame adaptation without creating ambiguous overloads against SwiftUI's existing `frame` methods.

Use a value type:

```swift
struct PlatformFrame: Hashable, Sendable {
    var minWidth: CGFloat?
    var idealWidth: CGFloat?
    var maxWidth: CGFloat?
    var minHeight: CGFloat?
    var idealHeight: CGFloat?
    var maxHeight: CGFloat?
    var alignment: Alignment
}
```

Required call form:

```swift
content
    .frame(
        iOS: PlatformFrame(maxWidth: .infinity),
        iPadOS: PlatformFrame(maxWidth: 720),
        macOS: PlatformFrame(maxWidth: 840)
    )
```

Also permit a two-value overload where iPad inherits iOS.

If scalar width or height use becomes repetitive, add narrowly named convenience overloads after source evidence establishes the exact signatures. Do not preemptively create a large modifier family.

### Generic use outside modifiers

Views may read:

```swift
@Environment(\.appPresentation) private var appPresentation
```

Then resolve any value:

```swift
let spacing = appPresentation.value(
    iOS: 10,
    iPadOS: 16,
    macOS: 20
)
```

This supplies the requested generic mechanism for values other than padding and frame without adding unnecessary `View` extensions.

## Client platform policy migration

### Remove authority terminology where it adds no value

The main platforms all receive the same product authority. The client no longer needs an `authoritative` versus `nonAuthoritative` policy split.

Replace it with explicit platform capabilities only for genuine differences:

- supports Live Activities;
- supports watch provisioning;
- supports camera capture;
- supports haptics;
- supports native notification registration;
- supports particular sharing or import adapter.

Remove or collapse:

- `Platform.Authority`;
- `isAuthoritative`;
- `allowsOwnerMutation`;
- `allowsCreatedTimetableMutation`;
- `allowsReceivedTimetableMutation`;
- `allowsSharing` where shared sharing exists;
- `allowsEditing`;
- `NonAuthoritativeRootView`;
- `NonAuthoritativeSettingsView`;
- `NonAuthoritativeAccountView` when replaced by shared account UI.

Keep `Platform.current` only if platform identity remains useful for session registration, notifications, logging, and feature adapters.

### Bootstrap

All three main platforms perform the same owner reconciliation and full account bootstrap.

Watch performs a shared read-only bootstrap using the shared services or shared download operations. It does not receive a separate duplicate networking stack.

Separate service interfaces into read and mutation operations where needed so the watch target can compile and call reads without exposing mutation UI.

## Server authority migration

### New capability contract

Main platforms:

- iOS: full main-app capabilities;
- iPadOS: full main-app capabilities;
- macOS: full main-app capabilities.

Watch:

- read;
- logout.

Watch does not receive:

- mutate account;
- mutate settings;
- mutate owner timetable;
- mutate created timetable;
- mutate received timetable;
- mutate received name override;
- mutate notifications;
- mutate Live Activities;
- create watch session.

Watch provisioning remains an operation performed by a parent iPhone session.

### Simplify session authority

Because backwards compatibility is unnecessary, remove the duplicated `SessionAuthority` claim if the platform capability set fully determines authorization.

Recommended server shape:

- access and refresh tokens retain `platform` and session ID;
- authorization validates the persisted session platform against the token platform;
- `ClientPlatform.capabilities` supplies allowed operations;
- no separate authoritative/non-authoritative claim is signed or compared;
- watch validation additionally requires a valid parent iPhone session.

This removes an invariant that otherwise duplicates `ClientPlatform` and causes migration mismatches.

### Account creation

Set signup eligibility to true for:

- iOS;
- iPadOS;
- macOS.

Keep it false for:

- watchOS;
- legacy.

Update user-facing server error reasons accordingly.

### Forced sign-out migration

Use an explicit migration or release operation that invalidates sessions without deleting users or domain data.

Preserve:

- users;
- credentials;
- account profiles;
- owner timetables;
- created timetables;
- received timetable imports and overrides;
- friendships and requests;
- account settings;
- notification preferences;
- calendar events;
- event tags and subscriptions;
- profile media metadata;
- administration data;
- audit records.

Invalidate:

- existing main-app refresh sessions;
- existing watch child sessions;
- active watch uniqueness keys as required;
- access tokens through session invalidation.

The migration must not delete accounts.

### Deployment order

Backwards compatibility is not required, but the deployment must avoid data loss:

1. Finish and commit server contract.
2. Finish and commit compatible clients.
3. User creates a database backup.
4. User reviews the migration target.
5. Deploy server and run migrations.
6. Existing sessions become invalid.
7. Release or install the new clients.
8. Sign in again.
9. Re-provision watch from iPhone.

## Feature migration sequence

### Authentication and onboarding

- Start from the current iPhone onboarding and authentication UI.
- Make onboarding available on iPadOS and macOS.
- Preserve iPhone UI.
- Replace separate Mac and iPad sign-in-only gates.
- Allow signup on all main platforms.
- Adapt window sizing and input controls natively.
- Keep watch provisioning authentication separate.
- Route onboarding pages through the shared router when external or tutorial navigation requires it.

### Timetable

- Preserve Today, Week, and Planner composition.
- Preserve the existing picker.
- Remove outer navigation ownership from `TimetableView` where the shell supplies it.
- Extract `mainView`, `mainContent`, labels, and comparison components into focused views where they exceed the file rule.
- Replace `Device.isIPad` padding with presentation-based values.
- Isolate watch activation from Timetable rendering.
- Move comparison state into router-owned inspector/presentation state at regular width.
- Keep compact comparison behavior equivalent to iPhone.
- Keep existing Dynamic Type constraint.

### Friends

- Promote the complete iPhone Friends feature.
- Preserve current list, search, ordering, request, and add-friend behavior.
- Keep compact friend detail presentation equivalent to iPhone.
- Use a large popover at regular width initially.
- Expose bounded friend and request content in the sidebar.
- Split `FriendDetailView.swift` aggressively by component ownership.
- Keep reusable row and card views independent.

### Settings

- Promote current `SettingsView` as the content reference.
- Remove `NonAuthoritativeSettingsView`.
- Keep compact pushes and sheets equivalent to iPhone.
- Map suitable settings routes to inspectors on regular width.
- Use large popovers for bounded viewing content.
- Retain sheets for confirmation and isolated editing.
- Add the navigation-persistence setting.
- Keep current sheet detents unchanged.
- Keep existing custom controls.
- Adapt keyboard-specific modifiers without duplicating the entire view.
- Expose settings categories in the sidebar.

### Account and profile

- Promote the complete iPhone account view.
- Support account mutations everywhere.
- Provide the complete profile appearance workflow on macOS.
- Abstract photo input while sharing crop, processing, appearance, and upload behavior.
- Keep camera-only functionality conditional where hardware/frameworks require it.
- Preserve account deletion semantics and confirmation.

### Created and received timetables

- Promote current iPhone management UI.
- Enable full server capabilities on iPadOS and macOS.
- Keep compact navigation equivalent to iPhone.
- Evaluate a nested split view for received timetable management in the sidebar detail.
- Ensure nested split selection does not interfere with the outer sidebar.
- Route timetable identifiers through `AppRoute`.

### Sharing

- Promote share-alias editing everywhere.
- Start with SwiftUI-provided sharing APIs.
- Keep share URL generation and server semantics shared.
- Retain platform adapters only for missing SwiftUI capabilities.
- Preserve Messages extension behavior and URLs.
- Route imported links through the shared router.

### Administration

- Promote all current iPhone administration tools.
- Keep Administration in a separate sidebar section.
- Expose direct administration tool shortcuts in the sidebar.
- Keep compact NavigationLink behavior.
- Prefer inspectors for suitable regular-width details and editors.
- Retain sheets for confirmations and isolated editors.
- Preserve authority invalidation behavior.
- Ensure removal of the Administration destination selects a safe fallback and dismisses restricted inspectors.

### Notifications

- Register and send notifications for iPhone, iPadOS, macOS, and watchOS only according to the intended device contract.
- The server retains platform identity for device records and APNs routing.
- Main platforms may mutate notification preferences.
- Watch reads shared notification settings but does not mutate them.
- Remove any watch-only settings write endpoint use.
- Keep Live Activity token operations iPhone-only.

## watchOS cleanup

### Behavior contract

Watch is read-only after provisioning.

It may:

- receive a child session provisioned by iPhone;
- refresh that child session while its iPhone parent remains valid;
- download required account/profile data;
- download owner timetable data;
- download received/friend data required by the current UI;
- download account settings;
- sign out.

It may not:

- create an independent account session;
- create an account;
- edit account data;
- edit owner timetable;
- edit created or received timetables;
- edit friends;
- edit settings;
- edit notification preferences;
- register mutation-only state.

### Shared backend

- Reuse shared `NetworkManager`, DTOs, session storage, and download services.
- Remove duplicate watch networking logic where shared code provides the same contract.
- Keep only watch provisioning and watch-specific lifecycle coordination under `Watch/Backend`.
- Do not make shared mutation methods visible through watch UI.
- Server authorization remains the final enforcement boundary.

### UI cleanup

- Remove the Highlight Current Day toggle.
- Remove any other mutation control found during audit.
- Keep read-only display of shared settings only when it contributes to existing UI.
- Preserve current screen hierarchy and appearance.
- Internal animation implementation may change if the rendered result remains equivalent.
- Do not split the watch status overlay merely to satisfy a mechanical one-type rule unless clarity materially improves.

### Widgets

The Watch Widget target packages shared widget families; it is not treated as a separate watch-only feature design project.

- Preserve existing families and UI.
- Keep shared widget source organized under `Widget`.
- Exclude main-platform layout modifiers from watchOS compilation.
- Validate target membership after shared file moves.

## File and folder organization

### Folder rules

Use real filesystem folders.

Proposed top-level organization:

```text
Main/
├── App/
├── Backend/
├── Navigation/
├── Platform/
│   ├── Shared/
│   ├── iOS/
│   └── macOS/
├── Tabs/
│   ├── Timetable/
│   ├── Friends/
│   ├── Settings/
│   └── Administration/
└── Views/

Shared/
├── Models/
├── Layout/
├── Networking-compatible support/
└── Utilities/

Watch/
├── App/
├── Backend/
├── Tabs/
└── Views/

Widget/
├── Widget Shared/
├── Widget/
└── Watch Widget/

Special/
├── Assets/
├── Entitlements/
├── Generated/
├── Info/
└── Localized resources/
```

Do not move feature-specific tab views into `Shared` merely because iPhone, iPadOS, and macOS all use the same target. They remain in their tab folder.

Use `Shared` for declarations shared across products or targets, such as models, DTOs, router URL contracts needed by extensions, and layout primitives compiled by multiple targets.

### View file rule

- One primary `View` struct per file.
- A private file-level or nested secondary view may remain when it is small, single-use, and improves local clarity.
- Reused views move to separate files.
- Large secondary views move to separate files.
- Sheets and inspectors that represent meaningful screens move to separate files.
- View models occupy separate files.
- Shapes and Layout conformances occupy separate files when non-trivial or reused.
- Do not split tiny local implementation details merely to satisfy line counting.
- Clarity and ownership override formalism.

### DTO rules

- Shared DTOs used across multiple services or targets live in shared DTO files grouped by contract domain.
- A one-use private DTO may appear above the declaration that owns it.
- Do not hide reusable DTOs inside feature views.

### Extension rules

Avoid extensions for project-owned types when methods can live naturally in the original declaration.

Extensions remain appropriate for:

- external types such as `View`, `Notification.Name`, `Color`, or framework protocols;
- conditional protocol conformances that require separation;
- generated or target-specific conformance boundaries where moving the declaration is impossible.

Audit and fold project-owned extensions back into their declarations where doing so improves clarity and does not create cross-target compilation problems.

### Naming rules

- Use normal title case for new and renamed files.
- Prefer filenames matching their primary declaration.
- Do not rename every historical lowercase file mechanically.
- Rename only when files move or split and the new name improves clarity.

### Resources

- Preserve all generated and localization files.
- Move generated resources to `Special/Generated` when target membership remains correct.
- Move asset catalogs to `Special/Assets` when target membership remains correct.
- Keep entitlements and Info property lists under `Special`.
- Do not combine resource moves with behavioral feature changes.

## Initial file-splitting map

### `Main/TimetableApp.swift`

Extract:

- `ImportResult` if still required;
- app route intake;
- shared timetable import coordination;
- authentication root;
- iPhone launch overlay host;
- macOS command definitions;
- macOS window coordination.

Remove:

- `WindowMode` if inspectors eliminate content-sized window expansion;
- separate non-authoritative roots;
- custom macOS background;
- fixed window frames.

### `Main/Tabs/ContentView.swift`

Replace with:

- `CompactAppShell.swift`;
- `MainTab.swift`;
- tab-specific navigation hosts;
- shared tab transition modifier if required.

Delete the UIKit controller bridge after parity.

### `Main/Tabs/NonAuthoritativeRootView.swift`

Delete after `SidebarAppShell` provides full feature parity.

### `Main/Tabs/Settings/NonAuthoritativeSettingsView.swift`

Delete after shared Settings compiles and functions on iPadOS/macOS.

### `Main/Tabs/Timetable/TimetableView.swift`

Extract:

- timetable paging root;
- week timetable content;
- selected-subject summary;
- session grid;
- session labels;
- comparison presentation coordination.

### `Main/Tabs/Friends/FriendDetailView.swift`

Extract each large private view and supporting relationship model according to reuse and ownership. Preserve visual composition.

### `Main/Tabs/Timetable/CalendarEventsView.swift`

Extract:

- Planner timeline model;
- no-school detail;
- event editor;
- event symbol picker;
- presentation routes;
- event-scope declarations.

### `Main/Views/StatusBadgeOverlay.swift`

Keep the public overlay entry in one file. Move large reusable visual components and shapes to focused files. Isolate UIKit/AppKit overlay hosting from the shared SwiftUI badge content.

### `Main/Views/TabsView.swift`

Delete if no feature uses the custom UIKit/AppKit control after the shell migration. If the Today/Week/Planner picker still uses it, isolate only that picker and its platform representable adapters; do not use it for root navigation.

### `Main/Tabs/Settings/SettingsView.swift`

Extract:

- account header/background;
- settings sections where they own state or substantial composition;
- navigation-persistence control;
- developer status-badge controls;
- shared mutation bindings into a settings model where appropriate.

### `Main/Tabs/Settings/AccountAndSyncSettingsView.swift`

Move each substantial notification editor and sheet into its own file.

### `Main/Tabs/Administration/AdministrationUserEditor.swift`

Move JSON formatting views and formatter logic into focused files while keeping one-use DTOs local where appropriate.

### `App Shared/Networking/AccountDTOs.swift`

Split only by server contract domain when it materially improves navigation. DTOs used by multiple targets remain shared. Avoid hundreds of one-DTO files.

## Xcode project membership plan

### Main target

Remove iOS-only filters from features that become shared:

- received timetable management;
- created timetable management;
- share selection and alias editing;
- full settings;
- onboarding;
- subject editing;
- profile editing components where adapted;
- other iPhone reference features promoted to macOS.

Retain or introduce platform filtering only for:

- MobileAppDelegate;
- AppDelegate;
- WatchConnectivity bridge;
- Live Activity registration;
- platform-only visual adapters;
- platform-only photo input adapters;
- launch illusion;
- macOS window coordination.

### Dependencies

Audit every platform-filtered package:

- determine whether the feature still requires it;
- determine whether it supports native macOS;
- isolate it behind an adapter if not;
- remove it if the native SwiftUI implementation replaces it;
- do not retain a UIKit dependency merely to preserve obsolete root navigation.

### Widgets and extensions

After every shared file move, confirm membership for:

- Timetable;
- Watch;
- Widget;
- Watch Widget;
- Messages;
- TimetableTests where relevant.

## Sheet, inspector, and popover rules

- Leave current sheet detents unchanged.
- Do not perform a global matched-transition rewrite.
- Preserve current namespaces and transition source IDs.
- New sheets follow the project matched-transition convention.
- New small sheets use a fraction between 0.5 and 0.7 unless their content requires another existing pattern.
- Confirm buttons include a system image, `.glassProminent`, and `.confirm`.
- Cancel buttons use the cancel role without redundant text-only styling.
- Viewing content on regular width prefers popover or inspector.
- Settings and Administration routes suitable for side inspection prefer inspector.
- Confirmation and isolated editing retain sheets.
- Compact presentations push where the current iPhone behavior pushes.
- Presentation choice is centralized in router policy.

## Implementation phases and commits

Each phase ends with source review, `git diff --check`, an atomic commit, and the applicable user build gate. Codex does not build.

### Phase 1 — Foundation inventory

Work:

- finalize the route inventory;
- finalize the platform conditional inventory;
- finalize Xcode platform filters;
- map feature presentations;
- record resource moves.

Expected commit: documentation only if the inventory changes this plan.

### Phase 2 — Shared presentation values

Work:

- add `AppPresentation`;
- add environment value;
- add generic `value` methods inside the declaration;
- add padding modifiers;
- add frame value and modifiers;
- expose to iOS/macOS widgets;
- exclude watchOS.

Expected commit:

`add shared platform layout values`

### Phase 3 — Shared route contract

Work:

- define route enums;
- define route URL codec;
- define root destinations;
- adapt existing deep links;
- adapt widget and App Intent route generation without changing UI.

Expected commit:

`add shared app route contract`

### Phase 4 — Per-window router

Work:

- add router;
- add compact paths;
- add sidebar state;
- add inspector state;
- add pending external route handling;
- add persistence setting and storage contract;
- keep current iPhone shell temporarily attached.

Expected commit:

`add per-window app router`

### Phase 5 — iPhone SwiftUI shell

Work:

- replace UIKit root tab controller;
- preserve tabs and transitions;
- create independent stacks;
- route notifications and links through router;
- preserve iPhone feature roots;
- remove obsolete controller bridge.

Expected commits:

- `add compact tab navigation shell`
- `remove legacy tab controller bridge`

User gate: iPhone build and reference comparison.

### Phase 6 — Server capability contract

Work in pmstt:

- give iOS/iPadOS/macOS full capabilities;
- permit signup on all main platforms;
- remove redundant session authority claim;
- keep watch read/logout only;
- keep iPhone-parented watch provisioning;
- add forced session invalidation migration;
- preserve all user data.

Expected commits:

- `unify main platform capabilities`
- `invalidate legacy platform sessions`

No deployment during implementation.

### Phase 7 — Client policy unification

Work:

- remove main-platform mutation restrictions;
- unify bootstrap;
- retain genuine feature capability flags;
- prepare full features for macOS target membership.

Expected commit:

`unify main platform client policy`

### Phase 8 — Sidebar shell

Work:

- add adaptive root selection;
- add two-column sidebar shell;
- add native sidebar sections;
- add root selection and visibility persistence;
- add compact/regular route translation;
- keep detail views close to current iPhone composition.

Expected commits:

- `add adaptive sidebar navigation`
- `add contextual sidebar content`

User gate: iPad and macOS builds, then width-transition review.

### Phase 9 — Authentication parity

Work:

- share iPhone onboarding;
- add iPad/macOS adaptations;
- remove sign-in-only gates;
- enable account creation everywhere;
- preserve watch provisioning.

Expected commit:

`expand authentication to all main platforms`

### Phase 10 — Timetable parity

Work:

- promote full timetable UI;
- add presentation values;
- add comparison inspector;
- isolate watch connectivity;
- split large views.

Expected commits:

- `expand timetable to all main platforms`
- `present timetable comparison in inspector`
- `split timetable view components`

### Phase 11 — Friends parity

Work:

- promote full Friends feature;
- add sidebar content;
- add large detail popover;
- split files.

Expected commits:

- `expand friends to all main platforms`
- `add friends sidebar content`
- `split friend detail components`

### Phase 12 — Settings and account parity

Work:

- promote full Settings;
- remove reduced Settings;
- add inspectors/popovers;
- add navigation persistence control;
- provide full macOS profile workflow;
- split files.

Expected commits:

- `expand settings to all main platforms`
- `add settings inspector navigation`
- `add navigation persistence setting`
- `expand profile editing to macOS`
- `remove non authoritative settings`

### Phase 13 — Timetable management and sharing parity

Work:

- created timetable management;
- received timetable management;
- nested split evaluation;
- share alias;
- SwiftUI sharing;
- link routing.

Expected commits:

- `expand timetable management to all platforms`
- `add received timetable split navigation`
- `expand timetable sharing to all platforms`

### Phase 14 — Administration parity

Work:

- promote every administration feature;
- add separate sidebar section;
- add inspector mapping;
- preserve compact flows;
- split large files.

Expected commits:

- `expand administration to all main platforms`
- `add administration inspector navigation`
- `split administration views`

### Phase 15 — macOS window and command completion

Work:

- remove fixed sizing;
- remove material background;
- add minimum size;
- enable multiple windows;
- add commands and toolbar behavior;
- isolate window state.

Expected commits:

- `modernize macos window behavior`
- `add macos sidebar commands`

### Phase 16 — Watch read-only cleanup

Work:

- adopt shared backend reads;
- remove mutation calls and controls;
- remove Highlight Current Day toggle;
- preserve UI;
- keep provisioning and lifecycle adapters.

Expected commits:

- `share watch backend services`
- `make watch settings read only`

### Phase 17 — Filesystem and resource organization

Work:

- move source into real folders;
- move shared resources and assets under `Special`;
- fold unnecessary project-owned extensions;
- update target membership;
- preserve generated/localized resources.

Expected commits grouped only by safe move scope:

- `organize shared platform source`
- `organize timetable feature source`
- `organize friends feature source`
- `organize settings feature source`
- `organize administration feature source`
- `organize special resources`

### Phase 18 — Remove obsolete architecture

Delete only after full parity:

- `NonAuthoritativeRootView`;
- `NonAuthoritativeSettingsView`;
- `NonAuthoritativeAccountView` if unused;
- old authority policy;
- obsolete platform filters;
- old root tab controller;
- unused custom macOS material background;
- dead platform-specific copies;
- dead discovery-era UI or services confirmed unused.

Expected commit:

`remove obsolete platform architecture`

### Phase 19 — Release gate

No Codex build or deployment.

User completes:

- all scheme builds;
- runtime matrix;
- database backup;
- server build;
- migration review;
- deployment;
- forced sign-in verification;
- watch reprovisioning;
- final data-loss audit.

## Source verification permitted without building

Codex may perform:

- `rg` source and target membership audits;
- `git status`;
- `git diff`;
- `git diff --check`;
- project-file inspection;
- route and DTO contract inspection;
- migration-order inspection;
- formatting inspection;
- commit inspection.

These checks do not establish compilation, SwiftUI appearance, navigation behavior, database migration behavior, notification delivery, or runtime correctness.

## Risks and controls

### Route translation loses state

Risk: changing between compact tab navigation and sidebar/inspector navigation can destroy paths or present the wrong destination.

Control:

- store logical routes independently of view instances;
- define explicit compact and regular presentation mappings;
- preserve unsaved editors as modal presentation state;
- restore only stable identifiers;
- validate every width transition in the user checklist.

### Existing tokens become invalid unexpectedly

Risk: removing the authority claim breaks refresh validation.

Control:

- intentionally invalidate all sessions;
- preserve users and domain data;
- deploy compatible clients and server together;
- require reauthentication;
- re-provision watch.

### macOS compilation is blocked by iOS-only dependencies

Risk: promoting an entire iPhone file exposes UIKit-only imports, package products, keyboard modifiers, photo APIs, or visual effects.

Control:

- extract shared feature content first;
- isolate dependencies behind small adapters;
- adjust project membership narrowly;
- retain current custom controls where supported;
- let the user build each platform after each feature phase.

### Nested split views conflict

Risk: received timetable nested split navigation fights outer column visibility or toolbars.

Control:

- implement only after the outer split stabilizes;
- keep inner selection scoped to the feature;
- provide a regular list/detail fallback inside the outer detail if nesting proves unstable.

### Multiple macOS windows share state accidentally

Risk: singleton router or global presentation values cause one window to change another.

Control:

- per-window router;
- per-window namespace;
- per-window inspector and sheet state;
- global services only for synchronized model data.

### File moves obscure behavioral diffs

Risk: large rename diffs hide bugs.

Control:

- separate moves from behavior;
- commit moves atomically;
- avoid formatting unrelated code during moves;
- review target membership after each folder phase.

### Watch accidentally gains mutation access

Risk: shared backend exposes mutation methods or server capabilities.

Control:

- remove mutation UI;
- use read-only watch flows;
- grant server watch only read/logout;
- keep server enforcement authoritative;
- verify forbidden requests during user runtime testing if needed.

### iPhone regresses during extraction

Risk: restructuring root navigation or extracting views changes layout and interaction.

Control:

- reference screenshots;
- iPhone-first phase ordering;
- preserve feature bodies before adapting them;
- user build and visual gate after every shell or feature phase;
- no broad UI cleanup during parity work.

## Definition of complete

The platform merge is complete only when:

- one main target supplies the complete iPhone, iPadOS, and macOS product;
- iPhone retains its tab bar and reference UI;
- compact iPad behaves as the compact app;
- regular iPad and macOS use the native content-rich two-column sidebar;
- Settings and Administration use regular-width inspectors/popovers where specified;
- routing works from every in-app entry point, widgets, tutorials, App Intents, Messages, and Universal Links;
- route persistence follows the user setting;
- macOS supports multiple freely resizable windows with isolated navigation state;
- full main-platform server mutation capabilities work;
- account creation works on every main platform;
- legacy sessions are invalidated without deleting user data;
- watch remains iPhone-provisioned, read-only, and visually preserved;
- watch settings contain no Highlight Current Day mutation control;
- obsolete non-authoritative source is deleted;
- remaining platform-specific code represents genuine framework boundaries;
- folders and files follow the agreed clarity rules;
- applicable items in `USER_PLATFORM_MERGE_CHECKLIST.md` are complete;
- the user has completed all builds, runtime checks, migration checks, and deployment checks.
