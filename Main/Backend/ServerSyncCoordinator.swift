import Defaults
import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class ServerSyncCoordinator {
	static let shared = ServerSyncCoordinator()
	private var fullSyncTask: Task<Void, any Error>?
	private var profileTask: Task<Void, Never>?

	func syncEverything() async {
		guard SessionStore.shared.isAuthenticated else {
			showSignInRequired()
			return
		}
		if let fullSyncTask {
			_ = try? await fullSyncTask.value
			return
		}
		let badgeID = UUID()
		let total = 5
		var currentStage = "Profile"
		StatusBadgeManager.shared.addBadge(id: badgeID, title: "Syncing everything", secondaryText: "Profile", priority: 4, view: .progressViewAndGauge(currentStep: 1, totalSteps: total))
		let task = Task { @MainActor in
			try await Self.withTimeout { _ = try await SessionStore.shared.updateProfile(displayName: Defaults[.userDisplayName]) }
			currentStage = "Timetable"
			StatusBadgeManager.shared.updateBadge(id: badgeID, title: "Syncing everything", secondaryText: "Timetable", view: .progressViewAndGauge(currentStep: 2, totalSteps: total))
			try await Self.withTimeout { try await OwnerTimetableSyncService.shared.uploadOwnerTimetable() }
			currentStage = "Account settings"
			StatusBadgeManager.shared.updateBadge(id: badgeID, title: "Syncing everything", secondaryText: "Account settings", view: .progressViewAndGauge(currentStep: 3, totalSteps: total))
			try await Self.withTimeout { try await AccountSettingsSyncService.shared.flushPendingSettings() }
			currentStage = "Received timetables"
			StatusBadgeManager.shared.updateBadge(id: badgeID, title: "Syncing everything", secondaryText: "Received timetables", view: .progressViewAndGauge(currentStep: 4, totalSteps: total))
			try await Self.withTimeout { try await ReceivedTimetableSyncService.shared.uploadCurrentProjection() }
			currentStage = "Authored timetables"
			StatusBadgeManager.shared.updateBadge(id: badgeID, title: "Syncing everything", secondaryText: "Authored timetables", view: .progressViewAndGauge(currentStep: 5, totalSteps: total))
			try await Self.withTimeout { try await AuthoredTimetableService.shared.refresh() }
			WidgetCenter.shared.reloadAllTimelines()
		}
		fullSyncTask = task
		do {
			try await task.value
			StatusBadgeManager.shared.updateBadge(id: badgeID, title: "Everything is synced", secondaryText: nil, view: .success)
		} catch {
			if !Self.suppresses(error) { StatusBadgeManager.shared.updateBadge(id: badgeID, title: "Sync failed at \(currentStage)", secondaryText: error.localizedDescription, view: .error) }
		}
		fullSyncTask = nil
	}

	private static func withTimeout(_ operation: @escaping @MainActor @Sendable () async throws -> Void) async throws {
		try await withThrowingTaskGroup(of: Void.self) { group in
			group.addTask { try await operation() }
			group.addTask {
				try await Task.sleep(for: .seconds(25))
				throw NetworkError.timedOut
			}
			_ = try await group.next()
			group.cancelAll()
		}
	}

	func ownerTimetableChanged() {
		guard SessionStore.shared.isAuthenticated else { return }
		Task { do { try await OwnerTimetableSyncService.shared.uploadOwnerTimetable() } catch { Self.showSyncFailure(error, title: "Timetable sync failed") } }
	}

	func scheduleProfileUpdate(_ displayName: String) {
		guard SessionStore.shared.isAuthenticated else { return }
		profileTask?.cancel()
		profileTask = Task {
			try? await Task.sleep(for: .milliseconds(500))
			guard !Task.isCancelled else { return }
			do {
				_ = try await SessionStore.shared.updateProfile(displayName: displayName)
				StatusBadgeManager.shared.addBadge(id: UUID(), title: "Preferences saved", priority: 3, view: .success)
			} catch { Self.showSyncFailure(error, title: "Profile sync failed") }
		}
	}

	private func showSignInRequired() {
		StatusBadgeManager.shared.addBadge(id: UUID(), title: "Sign in required", secondaryText: "Sign in to use this feature.", priority: 3, view: .warning)
	}

	private static func suppresses(_ error: any Error) -> Bool {
		(error as? NetworkError)?.suppressesStatusBadge == true
	}

	private static func showSyncFailure(_ error: any Error, title: String) {
		guard !suppresses(error) else { return }

		StatusBadgeManager.shared.addBadge(id: UUID(), title: title, secondaryText: error.localizedDescription, priority: 4, view: .error)
	}
}
