import Defaults
import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class ServerSyncCoordinator {
	static let shared = ServerSyncCoordinator()
	private var profileTask: Task<Void, Never>?

	private static func withTimeout(_ operation: @escaping @MainActor @Sendable () async throws -> Void) async throws {
		let operationTask = Task { @MainActor in
			try await operation()
		}

		try await withThrowingTaskGroup(of: Void.self) { group in
			group.addTask { try await operationTask.value }
			group.addTask {
				try await Task.sleep(for: .seconds(25))
				operationTask.cancel()
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
		StatusBadgeManager.shared.signInRequired()
	}

	private static func suppresses(_ error: any Error) -> Bool {
		(error as? NetworkError)?.suppressesStatusBadge == true
	}

	private static func showSyncFailure(_ error: any Error, title: String) {
		guard !suppresses(error) else { return }

		StatusBadgeManager.shared.addBadge(id: UUID(), title: title, secondaryText: error.localizedDescription, priority: 4, view: .error)
	}
}
