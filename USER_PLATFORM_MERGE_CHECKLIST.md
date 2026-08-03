# Platform Merge User Checklist

This file contains every build, runtime, visual, signing, deployment, and product-verification task assigned to the user during the iPhone, iPadOS, macOS, and watchOS platform merge.

Codex must not mark an item complete unless the user explicitly reports that it passed. Codex does not run builds or tests.

## Current Phase 5 gate

- [ ] Close and reopen the Timetable project so Xcode regenerates the synchronized-folder build plan.
- [ ] Build the `Timetable` scheme for an iPhone destination after the iPhone shell migration.
- [ ] Report every compiler error verbatim.
- [ ] Confirm the iPhone bottom tab bar contains Timetable, Friends, Settings, and conditional Admin in the existing order.
- [ ] Confirm each tab preserves its own navigation path when switching tabs.
- [ ] Confirm notification-driven switches to Timetable and Settings still work.
- [ ] Confirm the navigation restoration toggle appears under the routed Navigation settings destination.

## Phase 6–7 gate

- [ ] Review pmstt commits before deployment.
- [ ] Confirm a recoverable production database backup exists before running `InvalidateLegacyPlatformSessions`.
- [ ] Run the pmstt migration only in the intended release window because it signs out every current client and watch session.
- [ ] Confirm registration succeeds from iPhone, iPad, and Mac after deployment.
- [ ] Confirm iPhone, iPad, and Mac sessions can perform account, settings, timetable, sharing, and notification mutations.
- [ ] Confirm watch sessions can read and log out but cannot mutate settings, notifications, timetables, or accounts.
- [ ] Confirm only an authenticated iPhone session can provision a watch session.
- [ ] Build the `Timetable` scheme for iPhone, iPad, and My Mac after the client policy change.

## Phase 8–12 gate

- [ ] Build the `Timetable` scheme for an iPhone destination and confirm the bottom tab bar is unchanged.
- [ ] Build the `Timetable` scheme for an iPad destination in compact and regular widths.
- [ ] Build the `Timetable` scheme for My Mac.
- [ ] Confirm iPad compact width uses the iPhone tab shell and regular width uses the two-column sidebar.
- [ ] Confirm switching between compact and regular widths preserves the selected root and translates the active route.
- [ ] Confirm sidebar selection and visibility restore only when Restore Navigation is enabled.
- [ ] Confirm the sidebar has Timetable, Personal, and separate Administration sections.
- [ ] Confirm iPhone, iPad, and Mac can sign in and create an account.
- [ ] Confirm the full onboarding appears on iPhone and iPad when onboarding is incomplete.
- [ ] Confirm watch authentication remains paired-iPhone provisioned.
- [ ] Confirm the full timetable renders on iPad and Mac without changing the iPhone layout.
- [ ] Confirm selecting a timetable subject opens the inspector on iPad and Mac.
- [ ] Confirm Friends search, requests, ordering, add-friend presentation, and friend details work on iPad and Mac.
- [ ] Confirm friend detail opens in the inspector on wide layouts and remains a sheet on iPhone.
- [ ] Confirm wide Settings exposes Account, profile editing, notifications, tags, navigation restoration, feedback, and About.
- [ ] Confirm Settings secondary destinations open in the inspector on iPad and Mac.
- [ ] Confirm profile name, monogram, font, emoji, colour, and photo behavior on Mac.
- [ ] Report every compiler error verbatim before Phase 13 begins.

## Phase 13–19 release gate

- [ ] Build `Timetable` for iPhone, iPad, and My Mac after timetable management promotion.
- [ ] Verify created timetable create, edit, delete, and subject editing on all main platforms.
- [ ] Verify received timetable deletion, file import, file export, and native link sharing on all main platforms.
- [ ] Verify custom share-link creation, replacement, removal, and deep-link import.
- [ ] Verify every Administration destination opens as a push on iPhone and an inspector on iPad/macOS.
- [ ] Verify all administrator editors, confirmations, refreshes, and system-owner-only destinations.
- [ ] Verify macOS windows are freely resizable with an 800×600 minimum and no translucent custom background.
- [ ] Verify Command-1 through Command-4 select Timetable, Friends, Settings, and Administration.
- [ ] Verify multiple macOS windows maintain independent router state.
- [ ] Build `Watch` and confirm Settings contains no highlighting or mutation controls.
- [ ] Verify Watch server refresh, sign-out, iPhone provisioning, timetable reads, settings reads, and friend reads.
- [ ] Confirm no removed discovery UI or legacy tab controller remains reachable.
- [ ] Verify each target resolves only its own catalog from `Special/Assets` and reports no duplicate asset names.
- [ ] Build `Widget`, `Watch Widget`, `Messages`, and App Intents metadata after final target-membership changes.
- [ ] Create and verify a recoverable PostgreSQL backup.
- [ ] Review and run `InvalidateLegacyPlatformSessions` only during the selected release window.
- [ ] Build and validate pmstt without deploying.
- [ ] Deploy pmstt only after accepting forced sign-out for every client.
- [ ] Verify forced sign-in on iPhone, iPad, Mac, and Watch reprovisioning.
- [ ] Complete the final data-loss audit before distributing the client release.

## Phase 1–4 gate history

- [ ] Build the `Timetable` scheme for an iPhone destination.
- [ ] Build the `Timetable` scheme for an iPad destination.
- [ ] Build the `Timetable` scheme for My Mac.
- [ ] Build the `Widget` scheme.
- [ ] Build the `Watch Widget` scheme.
- [ ] Build the `Watch` scheme.
- [ ] Confirm the iPhone app still opens the current UIKit tab shell.
- [ ] Confirm `timetable://timetable` still opens Timetable.
- [ ] Confirm a current widget opens Timetable through the new route URL.
- [ ] Confirm an App Intent timetable destination opens Timetable.
- [ ] Report every compiler error verbatim before Phase 5 begins.

## Before implementation

- [ ] Create or confirm a recoverable PostgreSQL backup before the session-authority migration is deployed.
- [ ] Confirm that the current production database backup can be restored without deleting user records.
- [ ] Record the currently deployed pmstt commit.
- [ ] Record the currently distributed Timetable build number.
- [ ] Confirm that forced sign-out of every existing app and watch session is acceptable for the selected release.
- [ ] Confirm that no client/server backwards compatibility is required for the selected release.
- [ ] Confirm that the iPhone UI in the current source is the visual and behavioral reference.
- [ ] Capture reference screenshots of every iPhone tab and major presentation before the refactor.
- [ ] Capture reference screenshots of the current watch app before its structural cleanup.

## Reference screenshots

- [ ] Capture the signed-out iPhone authentication and onboarding states.
- [ ] Capture the iPhone Timetable Today screen.
- [ ] Capture the iPhone Timetable Week screen.
- [ ] Capture the iPhone Planner screen.
- [ ] Capture timetable comparison and subject detail presentations.
- [ ] Capture the iPhone Friends list, search, requests, and friend detail screens.
- [ ] Capture every iPhone Settings section and pushed destination.
- [ ] Capture every iPhone Administration section and editor available to a system owner.
- [ ] Capture profile editing, photo selection, cropping, emoji, font, and colour flows.
- [ ] Capture received and created timetable management.
- [ ] Capture sharing and share-alias flows.
- [ ] Capture every watch tab, signed-out state, status badge state, and timetable state.

## Xcode build gates

- [ ] Build the `Timetable` scheme for an iPhone destination after the shared-router foundation lands.
- [ ] Build the `Timetable` scheme for an iPad destination after the shared-router foundation lands.
- [ ] Build the `Timetable` scheme for My Mac after the shared-router foundation lands.
- [ ] Build the `Timetable` scheme for an iPhone destination after the iPhone shell migration.
- [ ] Build the `Timetable` scheme for an iPad destination after the sidebar shell lands.
- [ ] Build the `Timetable` scheme for My Mac after the sidebar shell lands.
- [ ] Build the `Timetable` scheme for all three main platforms after each feature-parity phase.
- [ ] Build the `Watch` scheme after the shared backend is adopted.
- [ ] Build the `Watch` scheme after watch mutation UI is removed.
- [ ] Build the `Widget` scheme after shared layout helpers or shared files move.
- [ ] Build the `Watch Widget` scheme after shared files move.
- [ ] Build the `Messages` scheme after router, sharing, or shared files move.
- [ ] Build `TimetableTests` only if explicitly requested for a later validation gate.

## iPhone regression verification

- [ ] Confirm the iPhone bottom tab bar remains present.
- [ ] Confirm the tab bar retains its current destinations, ordering, symbols, monospaced labels, and cross-dissolve where technically possible.
- [ ] Confirm every iPhone tab preserves an independent navigation path.
- [ ] Confirm Timetable matches the reference screenshots.
- [ ] Confirm Friends matches the reference screenshots.
- [ ] Confirm Settings matches the reference screenshots.
- [ ] Confirm Administration matches the reference screenshots.
- [ ] Confirm onboarding and authentication match the reference screenshots.
- [ ] Confirm all existing custom controls remain visually intact.
- [ ] Confirm existing sheets retain their current detents.
- [ ] Confirm existing matched transitions remain intact.
- [ ] Confirm dark appearance and monospaced typography remain intact.
- [ ] Confirm existing Dynamic Type constraints remain intact.
- [ ] Confirm incoming timetable links select the correct tab and destination.
- [ ] Confirm App Intent navigation reaches the correct in-app destination.
- [ ] Confirm widget links reach the correct in-app destination.
- [ ] Confirm tutorial navigation reaches the correct in-app destination.

## iPad compact-width verification

- [ ] Confirm narrow iPad Split View uses the compact iPhone layout values.
- [ ] Confirm narrow Stage Manager windows use the compact iPhone shell.
- [ ] Confirm compact-to-regular transitions do not lose the selected root destination.
- [ ] Confirm compact-to-regular transitions do not lose pushed navigation state when persistence is enabled.
- [ ] Confirm regular-to-compact transitions preserve the best equivalent route.
- [ ] Confirm editors that push on iPhone continue to push in compact iPad width.
- [ ] Confirm inspector content falls back to navigation or sheets when an inspector cannot fit.

## iPad regular-width verification

- [ ] Confirm the app uses a native two-column `NavigationSplitView`.
- [ ] Confirm the sidebar uses native Apple styling.
- [ ] Confirm Timetable is selected by default.
- [ ] Confirm Timetable, Friends, Settings, and Administration are available from the sidebar.
- [ ] Confirm Administration appears in a separate sidebar section.
- [ ] Confirm account/profile content appears in the sidebar.
- [ ] Confirm current or next class content appears in the sidebar.
- [ ] Confirm timetable switchers appear in the sidebar.
- [ ] Confirm received timetables appear in the sidebar.
- [ ] Confirm friends appear in the sidebar.
- [ ] Confirm pending friend requests appear in the sidebar.
- [ ] Confirm upcoming Planner events appear in the sidebar.
- [ ] Confirm Settings categories are reachable from the sidebar.
- [ ] Confirm Administration tools are reachable from the sidebar.
- [ ] Confirm creation actions are available in the sidebar.
- [ ] Confirm sidebar content updates contextually without making root navigation unstable.
- [ ] Confirm sidebar search works.
- [ ] Confirm sync status appears in the sidebar.
- [ ] Confirm the sidebar account control works.
- [ ] Confirm sidebar scrolling, fixed content, and safe areas behave correctly.
- [ ] Confirm native sidebar collapse and expansion work.
- [ ] Confirm sidebar visibility persists across launches.
- [ ] Confirm root selection persists across launches.
- [ ] Confirm navigation-path persistence follows the setting selected by the user.
- [ ] Confirm settings rows open large popovers, inspectors, or navigation according to width.
- [ ] Confirm administration rows open large popovers, inspectors, or navigation according to width.
- [ ] Confirm friend details use the intended large popover presentation.
- [ ] Confirm received timetables can use a nested split view without broken navigation.
- [ ] Confirm timetable comparison uses an inspector where practical.
- [ ] Confirm the Today/Week/Planner picker remains present.

## macOS verification

- [ ] Confirm macOS uses the two-column sidebar architecture.
- [ ] Confirm macOS has the same full feature set as iPhone except genuinely unavailable platform features.
- [ ] Confirm the window is freely resizable.
- [ ] Confirm the window still enforces a sensible minimum size.
- [ ] Confirm multiple windows work without sharing incorrect navigation or sheet state.
- [ ] Confirm each window owns its own router.
- [ ] Confirm each window owns its own namespace and presentation state.
- [ ] Confirm `Command-,` selects Settings in the existing window sidebar.
- [ ] Confirm `Command-1`, `Command-2`, and subsequent destination shortcuts select the corresponding sidebar destination.
- [ ] Confirm holding Command exposes the expected menu shortcut hints through normal macOS menu behavior.
- [ ] Confirm toolbar actions use native SwiftUI toolbar placement.
- [ ] Confirm timetable comparison uses an inspector or detail presentation in the same window.
- [ ] Confirm Settings and Administration destinations use inspectors or large popovers rather than unnecessary pushes.
- [ ] Confirm profile photo selection and cropping provide the full experience.
- [ ] Confirm SwiftUI sharing works.
- [ ] Confirm the removed translucent window background does not leave visual artifacts.
- [ ] Confirm no custom material window background remains.
- [ ] Confirm navigation and inspector state remain isolated between multiple windows.
- [ ] Confirm Universal Links route into the intended window and destination.

## Feature parity verification

- [ ] Create an account on iPhone.
- [ ] Create an account on iPad.
- [ ] Create an account on macOS.
- [ ] Sign in and sign out on iPhone.
- [ ] Sign in and sign out on iPad.
- [ ] Sign in and sign out on macOS.
- [ ] Edit account details on all three main platforms.
- [ ] Delete a test account on all three main platforms without affecting unrelated accounts.
- [ ] Edit the owner timetable on all three main platforms.
- [ ] Import a calendar timetable on iPhone and iPad.
- [ ] Import a calendar timetable on macOS if the final adapter exposes it.
- [ ] Create, edit, and delete created timetables on all three main platforms.
- [ ] Import, rename, and delete received timetables on all three main platforms.
- [ ] Edit the share alias on all three main platforms.
- [ ] Invoke platform sharing on all three main platforms.
- [ ] Add, accept, reorder, and remove friends on all three main platforms.
- [ ] Change shared account settings on all three main platforms.
- [ ] Change notification settings on all three main platforms.
- [ ] Verify notification registration on iPhone, iPad, and macOS.
- [ ] Verify notifications can be delivered to every registered platform.
- [ ] Use every administration mutation from iPhone, iPad, and macOS.
- [ ] Verify feedback submission from all three main platforms.
- [ ] Verify widgets receive current shared data after mutations from iPad and macOS.

## Router verification

- [ ] Verify every root destination has a stable route.
- [ ] Verify every pushed feature destination has a stable route.
- [ ] Verify inspector destinations have stable routes.
- [ ] Verify sheet and popover destinations have stable presentation routes where external navigation requires them.
- [ ] Verify routes can be encoded and decoded for restoration.
- [ ] Verify malformed route URLs fail safely.
- [ ] Verify unavailable administrator routes fall back safely.
- [ ] Verify deleted timetable, friend, event, and account identifiers fail safely.
- [ ] Verify tutorial actions can navigate through the router.
- [ ] Verify App Intents can navigate through the router.
- [ ] Verify widgets can generate router-compatible links.
- [ ] Verify Messages links remain router-compatible.
- [ ] Verify Universal Links remain router-compatible.
- [ ] Verify route restoration works when enabled.
- [ ] Verify route restoration is cleared when disabled.

## Server migration and release

- [ ] Build pmstt in the user-approved environment after the authority contract changes.
- [ ] Confirm the migration preserves users, timetables, friendships, events, settings, media, and administration data.
- [ ] Confirm the migration invalidates existing access and refresh sessions.
- [ ] Confirm old watch sessions are invalidated.
- [ ] Confirm new iPhone, iPadOS, and macOS sessions receive full main-app capabilities.
- [ ] Confirm new watch sessions receive read and logout capabilities only.
- [ ] Confirm watch provisioning remains parented to an iPhone session.
- [ ] Confirm account creation succeeds from iPhone, iPad, and macOS.
- [ ] Confirm old incompatible clients fail clearly after deployment.
- [ ] Deploy pmstt only after the database backup and migration review are complete.
- [ ] Restart the production service.
- [ ] Inspect production migration output.
- [ ] Inspect production logs for authentication, capability, or route failures.
- [ ] Sign back into every test platform after the forced sign-out.
- [ ] Confirm no user data was lost.

## watchOS verification

- [ ] Confirm watch provisioning still succeeds from iPhone.
- [ ] Confirm watch sign-in succeeds.
- [ ] Confirm watch sign-out succeeds.
- [ ] Confirm watch can read the owner timetable.
- [ ] Confirm watch can read friends and received timetable data required by its UI.
- [ ] Confirm watch reads shared account settings.
- [ ] Confirm the Highlight Current Day toggle has been removed from watch settings.
- [ ] Confirm watch has no remaining setting-mutation controls.
- [ ] Confirm watch cannot issue account, timetable, received timetable, created timetable, friend, or settings mutations.
- [ ] Confirm watch UI still matches the reference screenshots.
- [ ] Confirm watch animations remain visually acceptable after internal cleanup.
- [ ] Confirm the shared Watch Widget product still renders its existing shared widget families.

## Final acceptance

- [ ] Review the final source diff for unintended UI changes.
- [ ] Review the final Xcode project diff for incorrect platform membership.
- [ ] Review every removed `#if` and platform filter.
- [ ] Review every remaining platform conditional and confirm it represents a genuine framework or product boundary.
- [ ] Review folder organization in Finder and Xcode.
- [ ] Confirm moved asset catalogs and generated resources remain in `Special`.
- [ ] Confirm no user-owned unrelated changes were overwritten.
- [ ] Confirm all required atomic commits exist in both Timetable and pmstt.
- [ ] Confirm all applicable checklist items are complete before release.
