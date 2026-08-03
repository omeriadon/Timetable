# Main-Platform Merge Inventory

Date: 2026-08-03

This inventory is the Phase 1 source map for `PLATFORM_MERGE_PLAN.md`. It records the active navigation, platform-policy, target-membership, deep-link, presentation, and file-organization boundaries before implementation.

No build or runtime conclusion is represented here.

## Targets

| Target | Platforms | Relevant source roots | Merge role |
| --- | --- | --- | --- |
| Timetable | iPhone, iPadOS, native macOS | Shared, App Shared, App Intents, Main, Special | Complete main application |
| Watch | watchOS | Shared, App Shared, App Intents, Watch, Special | Separate read-only companion |
| Widget | iPhone, iPadOS, macOS | Shared, App Intents, Widget, Special | Shared main-platform widgets |
| Watch Widget | watchOS | Shared, App Intents, Widget, Special | watchOS packaging of shared widget families |
| Messages | iPhone, iPadOS | Messages | Share and import extension |
| TimetableTests | iPhone, iPadOS | Explicit test sources | User-run validation target |

The Timetable target already supports all three main platforms. No target merge or Catalyst conversion is required.

## Current authenticated roots

| Presentation | Root | Current feature set | Required replacement |
| --- | --- | --- | --- |
| iPhone | `ContentView` | Full Timetable, Friends, Settings, conditional Administration | `CompactAppShell` |
| iPadOS | `NonAuthoritativeRootView` | Timetable and reduced Settings | Adaptive compact or sidebar shell with full features |
| macOS | `NonAuthoritativeRootView` | Timetable and reduced Settings | `SidebarAppShell` with full features |
| watchOS | `WatchRootTabView` / `WatchSessionRootView` | Separate watch product | Preserve UI; use read-only shared backend |

## Current root navigation

### iPhone

- `ContentView` is compiled only under `os(iOS)`.
- `ProminentActionTabView` wraps `UITabBarController`.
- UIKit owns root tabs and their hosting controllers.
- `MainTab` is defined inside the iOS-only file.
- Administration is inserted and removed according to account authority.
- NotificationCenter selects Timetable and Settings tabs.
- Each UIKit tab constructs a SwiftUI feature root that currently owns its own `NavigationStack`.

### iPadOS and macOS

- `NonAuthoritativeRootView` uses a two-item SwiftUI `TabView`.
- Selection is an integer.
- Timetable and reduced Settings are the only roots.
- macOS content size is driven through `WindowMode` and an `expanded` binding.

### Required navigation ownership changes

- Move root selection to shared enums.
- Introduce a per-window router.
- Keep one independent path per compact tab.
- Use a two-column split root for regular iPad and macOS.
- Remove feature-owned outer `NavigationStack` containers as each feature migrates.
- Replace NotificationCenter navigation commands with router calls, retaining temporary compatibility shims only during migration.

## Current client platform policy

`Shared/Platform.swift` currently defines:

- iOS as authoritative;
- iPadOS, macOS, and watchOS as non-authoritative;
- account creation only on iOS;
- owner mutation only on iOS;
- created timetable mutation only on iOS;
- received timetable mutation only on iOS;
- sharing only on iOS;
- editing only on iOS.

Client enforcement occurs in:

- `SessionStore` for account creation and authoritative session operations;
- `OwnerTimetableSyncService`;
- `AuthoredTimetableService`;
- `ReceivedTimetableSyncService`;
- `TimetableShareAliasService`;
- `ServerSyncCoordinator`;
- `FeedbackService`;
- `TimetableDiscoveryService`;
- `AccountBootstrapService`.

These gates remain unchanged through Phases 1–4. They are removed during the client policy phase after the server capability contract is ready.

## Current server platform policy

pmstt currently defines:

- iOS: authoritative and full main-app capabilities;
- iPadOS: non-authoritative with read, logout, and notification mutation;
- macOS: non-authoritative with read, logout, and notification mutation;
- watchOS: non-authoritative with read, logout, and notification mutation;
- legacy: read and logout.

Additional constraints:

- signup is accepted only from iOS;
- normal login is accepted from iOS, iPadOS, and macOS;
- watch sessions are created only by iOS;
- watch sessions require an active iOS parent session;
- refresh payloads contain both platform and authority;
- capability middleware maps mutation routes to platform capabilities.

No server source changes occur during Phases 1–4.

## Deep-link and external navigation entry points

| Entry point | Current encoding | Current handling | Phase 3 destination |
| --- | --- | --- | --- |
| Widget summary | `timetable://timetable` | `TimetableApp.onOpenURL` | Shared `AppRoute` URL |
| Widget weekly schedule | `timetable://timetable` | `TimetableApp.onOpenURL` | Shared `AppRoute` URL |
| Widget friends time left | `timetable://timetable` | `TimetableApp.onOpenURL` | Shared `AppRoute` URL |
| Live Activity | `timetable://timetable` | `TimetableApp.onOpenURL` | Shared `AppRoute` URL |
| App Intent | URL generated by `IntentTimetableResolver` | `OpenURLIntent` then `TimetableApp` | Shared `AppRoute` URL |
| Spotlight timetable | `TimetableDeepLink` URL | NotificationCenter to `TimetableView` | Shared `AppRoute` URL |
| Spotlight subject | `TimetableDeepLink` URL with optional slot query | NotificationCenter to `TimetableView` | Shared `AppRoute` URL |
| Universal Link share | HTTPS share locator | Import then NotificationCenter | Import then router route |
| Messages share | HTTPS or queued locator | App Group queue and import | Import then router route |
| macOS Settings command | NotificationCenter | root tab selection | Direct router root selection |

The existing timetable URL forms must continue decoding:

- `timetable://timetable`
- `timetable://owner`
- `timetable://received/<id>`
- `timetable://owner/subject/<subject-id>`
- `timetable://received/<id>/subject/<subject-id>`
- optional `day` and `session` query values for a subject slot.

## Current major presentation state

### Timetable and Planner

- selected received timetable;
- selected slot;
- comparison visibility;
- Today/Week/Planner page selection;
- Planner presentation target;
- calendar event editor target;
- no-school detail target;
- event symbol picker.

### Friends

- friend add sheet;
- friend request sheet;
- selected friend detail;
- friend detail internal tab;
- subject context popover;
- report confirmation.

### Settings and account

- calendar import confirmation and sheet;
- subject editor sheet;
- feedback sheet;
- account deletion confirmation;
- profile appearance sheet;
- profile photo picker and crop editor;
- created timetable creation and editing;
- received timetable deletion, file import, file export, and sharing;
- notification schedule editors;
- tag selection.

### Administration

- school event editor;
- tag and tag-section editors;
- user editor;
- broadcast history detail;
- special badge editor;
- symbol pickers;
- destructive confirmations.

Phase 3 creates stable route identities. Existing local sheet and editor state remains in place until the corresponding feature migration.

## Files containing active platform compilation branches

### App and lifecycle

- `Main/TimetableApp.swift`
- `Main/iOS/MobileAppDelegate.swift`
- `Main/macOS/AppDelegate.swift`

### Backend

- `Main/Backend/AccountSettingsSyncService.swift`
- `Main/Backend/LiveActivityRegistrationService.swift`
- `Main/Backend/NotificationRegistrationService.swift`

### Root and feature views

- `Main/Tabs/ContentView.swift`
- `Main/Tabs/NonAuthoritativeRootView.swift`
- `Main/Tabs/Timetable/TimetableView.swift`
- `Main/Tabs/Timetable/TimetableComparison.swift`
- `Main/Tabs/Timetable/CalendarEventsView.swift`
- `Main/Tabs/Settings/SettingsView.swift`
- `Main/Tabs/Settings/NonAuthoritativeSettingsView.swift`
- `Main/Tabs/Settings/AccountAndSyncSettingsView.swift`
- `Main/Tabs/Settings/FeedbackView.swift`
- `Main/Tabs/Settings/ReceivedTimetablesView.swift`
- `Main/Tabs/Share/ShareSelectionSheet.swift`
- `Main/Tabs/Share/TimetableShareAliasSheet.swift`
- `Main/Tabs/Administration/AdministrationEventSymbolPicker.swift`
- profile photo and appearance files under `Main/Tabs/Settings/Profile`.

### Shared UI and adapters

- `Main/Views/TabsView.swift`
- `Main/Views/StatusBadgeOverlay.swift`
- `Main/Views/AppNavigationTitle.swift`
- `Main/Views/InlineColorPicker.swift`
- `Main/Views/Account/AccountView.swift`
- Subject Editor files.
- `Main/Components/CachedProfilePhoto.swift`
- `Shared/Device.swift`
- `Shared/HapticManager.swift`
- `Shared/Platform.swift`
- `Shared/RGBAColor.swift`
- `Shared/Rectangle.swift`
- `Shared/TimetableShareDocument.swift`

Every remaining branch must eventually be classified as a framework boundary, presentation adaptation, watch boundary, or obsolete branch.

## Main-target platform-filtered source

Current iOS-only source membership includes:

- Live Activity registration;
- PhoneWatchSyncBridge;
- timetable search/detail identity views;
- created timetable management;
- received timetable management;
- share selection and alias editing;
- UIKit blur and scroll effects;
- onboarding;
- Subject Editor main sheet;
- launch illusion.

Current macOS-only source membership includes:

- AppDelegate;
- CustomMaterialView;
- StatusBadgeOverlayWindow.

Promotion candidates are not unfiltered until their framework imports and dependencies are isolated.

## Platform-filtered dependencies

Current iOS-filtered dependencies include:

- FocusOnAppear;
- Sticker;
- SFSymbolsPicker;
- WindowOverlay;
- PortalHeaders;
- PortalTransitions.

Current macOS-filtered dependency:

- MaterialView.

IrregularGradient, Defaults, ColorfulX, and SwiftEmoji have broader current membership where configured.

The custom UIKit tab controller is removed without preserving UIKit solely for root navigation.

## Highest-priority structural files

| File | Current size | Primary issue |
| --- | ---: | --- |
| `FriendDetailView.swift` | 715 lines | Many private views and route/presentation models |
| `CalendarEventsView.swift` | 609 lines | Planner, editor, symbol picker, detail, and route targets combined |
| `StatusBadgeOverlay.swift` | 583 lines | Shared content and platform hosting concerns combined |
| `TodayTimetableView.swift` | 473 lines | Multiple timeline/card views and shapes |
| `TimetableApp.swift` | 452 lines | Scene, routing, imports, auth gates, and window behavior combined |
| `TabsView.swift` | 414 lines | UIKit/AppKit adapters and custom control combined |
| `AccountAndSyncSettingsView.swift` | 400 lines | Multiple editor views and sheet |
| `SettingsView.swift` | 372 lines | Full settings composition and substantial local components |
| `TimetableView.swift` | 356 lines | Root navigation, paging, grid, comparison, and deep-link handling combined |
| `AdministrationUserEditor.swift` | 352 lines | Editor and JSON formatting components combined |

No structural split occurs in Phases 1–4 except when required to establish a clean shared declaration boundary.

## Phase 1 completion conditions

- Main targets and source roots identified.
- Current platform roots identified.
- Client and server authority gates identified.
- Deep-link producers and consumers identified.
- Major sheet, popover, editor, and selection state identified.
- Platform-filtered feature files identified.
- Platform-filtered dependencies identified.
- High-risk structural files identified.
- No build or runtime behavior claimed.
