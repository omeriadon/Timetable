import Defaults
import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class ServerSyncCoordinator {
	static let shared = ServerSyncCoordinator()

	private var profileTask: Task<Void, Never>?

	private static func withTimeout<T>(
		_ operation: @escaping @MainActor () async throws -> T
	) async throws -> T {
		let operationTask = Task { @MainActor in
			try await operation()
		}

		return try await withThrowingTaskGroup(of: T.self) { group in
			defer {
				operationTask.cancel()
				group.cancelAll()
			}

			group.addTask {
				try await operationTask.value
			}

			group.addTask {
				try await Task.sleep(for: .seconds(25))
				operationTask.cancel()
				throw NetworkError.timedOut
			}

			guard let result = try await group.next() else {
				throw CancellationError()
			}

			return result
		}
	}

	func ownerTimetableChanged(subjects: [Subject]? = nil) {
		guard SessionStore.shared.isAuthenticated else {
			showSignInRequired()
			return
		}

		let snapshot = subjects ?? Defaults[.timetable]

		Task {
			do {
				_ = try await saveOwnerTimetable(snapshot)
			} catch {
				// saveOwnerTimetable already updates the visible badge.
			}
		}
	}

	func saveOwnerTimetable(_ subjects: [Subject]) async throws -> [Subject] {
		try Platform.require(Platform.current.allowsOwnerMutation)
		guard SessionStore.shared.isAuthenticated else {
			showSignInRequired()
			throw NetworkError.authenticationRequired
		}

		let badgeID = UUID()

		StatusBadgeManager.shared.addBadge(
			id: badgeID,
			title: "Syncing timetable",
			priority: 3,
			view: .progressView
		)

		do {
			let response = try await Self.withTimeout {
				try await OwnerTimetableSyncService.shared.uploadOwnerTimetableResponse(subjects: subjects)
			}

			Defaults[.ownerIsSearchable] = response.isSearchable
			Defaults[.lastServerSync] = Date.now

			StatusBadgeManager.shared.updateBadge(
				id: badgeID,
				title: "Timetable synced",
				view: .success
			)

			return response.subjects
		} catch {
			guard !error.isCancellation else { throw error }

			StatusBadgeManager.shared.updateBadge(
				id: badgeID,
				title: error.localizedDescription,
				view: .error
			)

			throw error
		}
	}

	func scheduleProfileUpdate(_ displayName: String) {
		guard SessionStore.shared.isAuthenticated, Platform.current.isAuthoritative else { return }

		profileTask?.cancel()

		profileTask = Task {
			try? await Task.sleep(for: .milliseconds(500))
			guard !Task.isCancelled else { return }

			do {
				_ = try await SessionStore.shared.updateProfile(displayName: displayName)

				StatusBadgeManager.shared.addBadge(
					id: UUID(),
					title: "Preferences saved",
					priority: 3,
					view: .success
				)
			} catch {
				Self.showSyncFailure(error, title: "Profile sync failed")
			}
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

		StatusBadgeManager.shared.addBadge(
			id: UUID(),
			title: title,
			secondaryText: error.localizedDescription,
			priority: 4,
			view: .error
		)
	}
}
