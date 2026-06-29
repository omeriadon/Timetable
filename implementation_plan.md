# Global Status Badge System

Implement a centralized, highly-animated status badge system to replace standard alerts and inline loading indicators. The system will display processes, successes, and errors as a capsule at the top of the screen with smooth transitions, interacting with a "Liquid Glass" background and handling multiple overlapping states gracefully.

## User Review Required

> [!IMPORTANT]
> The plan outlines a singleton-based architecture for `StatusBadgeManager` and an `.overlay` at the root of `ContentView`. Please review the logic for how badges are prioritized and cycled, as well as how they auto-delete (by being updated to a success or error state).

## Open Questions

> [!WARNING]
> 1. **Auto-deletion logic**: You mentioned "delete badge needs to be automatically deleting, no function for that." Since processes (like API calls) take a variable amount of time, is the intended flow that a process is started with `addBadge(... view: .progressview)`, and when it finishes, we call `updateBadge(... view: .success)` which then auto-dismisses after 2 seconds? This would explain why no `deleteBadge` is needed.
> 2. **Mini-badge interactions**: When tapping the mini progressive circle to switch between badges, should the "cycle" automatically pause or adjust priority temporarily so the user can inspect the badge, or does it just strictly show the next highest priority item in the queue?
> 3. **Badge Model Enum**: Are the steps for `.circulargague` and `.progressviewAndGague` `Int`s or `Double`s? (Assuming `Int` for steps for now).
> 4. **Liquid Glass Background**: I'll use standard `Material` or `ultraThinMaterial` backgrounds that blend together if you haven't defined a custom `LiquidGlass` view yet. Let me know if you already have a specific `LiquidGlass` modifier or view in the project.

## Proposed Changes

### Global State & Manager

#### [NEW] [StatusBadgeManager.swift](file:///Users/omeriadon/Documents/Xcode_App_Library/Timetable/Main/Views/StatusBadgeManager.swift)
- Create a global `StatusBadgeManager` observable class (using `@Observable` or `ObservableObject`) accessible via a shared singleton `StatusBadgeManager.shared`.
- Define the `BadgeViewEnum`:
  ```swift
  enum BadgeViewEnum {
      case progressview
      case success
      case error
      case warning
      case circulargague(currentStep: Int, totalSteps: Int)
      case progressviewAndGague(currentStep: Int, totalSteps: Int)
  }
  ```
- Define a `StatusBadge` struct holding: `id`, `title`, `secondaryText`, `dismissible`, `priority` (1-5), `viewState` (`BadgeViewEnum`), and `createdAt` timestamp.
- Implement the requested functions safely:
  - `addBadge(id: UUID, title: String, secondaryText: String, dismissable: Bool, priority: Int, view: BadgeViewEnum)`
  - `updateBadge(id: UUID, title: String, secondaryText: String, view: BadgeViewEnum)`
- Implement automatic cleanup logic: When a badge is updated to `.success` (2s delay) or `.error` (5s delay), schedule a `Task` to remove it from the active list.
- Keep track of the currently "focused" badge and any hidden background badges.

### UI Components

#### [NEW] [StatusBadgeOverlay.swift](file:///Users/omeriadon/Documents/Xcode_App_Library/Timetable/Main/Views/StatusBadgeOverlay.swift)
- A view that reads from `StatusBadgeManager.shared` and renders the badges.
- **Main Badge**: Takes 2/5 screen width, centered at the top. Shows icon/progress, title, and optional secondary text.
- **Mini Badge**: Shown on the left if there are 2 or more active badges. Uses a `.blurReplace` transition on both platforms. Tapping cycles the currently focused badge.
- **Transitions**: 
  - macOS: `.blurReplace`
  - iOS: `.offset(y: -100)` combined with opacity or standard `.move(edge: .top)`.
- **Gestures**: 
  - iOS: `DragGesture` (swipe up) to dismiss (if dismissible).
  - macOS: `onContinuousHover` + Scroll event modifier (or native trackpad scroll gestures) to dismiss.
- **Animations**: Uses `withAnimation(.spring(response: 0.4, dampingFraction: 0.8))` (or similar Apple-like spring) for layout changes, including the main badge shifting left when the mini badge appears.

### View Injection

#### [MODIFY] [ContentView.swift](file:///Users/omeriadon/Documents/Xcode_App_Library/Timetable/Main/Views/ContentView.swift)
- Add the `StatusBadgeOverlay()` using `.overlay(alignment: .top)` to the outermost layer of the application so it covers everything but stays within the window/safe area bounds.

## Verification Plan

### Manual Verification
- We will add a temporary debug button in settings or on the main view to spawn multiple badges (progress, error, success) with different priorities to verify:
  1. The overlay animates in correctly (offset on iOS, blurReplace on macOS).
  2. Spawning a second badge makes the main badge slide left and the mini badge appear via blurReplace.
  3. Cycling through badges works.
  4. Success auto-dismisses in 2s, Error in 5s.
  5. Swipe up / Scroll dismiss gestures work perfectly.
