import Defaults
import Foundation
import Observation

@MainActor
@Observable
final class GradeTrackerService {
	static let shared = GradeTrackerService(networkManager: .shared)

	private let networkManager: NetworkManager
	private var refreshTask: Task<Void, any Error>?

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func refresh() async throws {
		if let refreshTask {
			try await refreshTask.value
			return
		}

		let task = Task { @MainActor in
			let response: GradeTrackerResponse = try await networkManager.send(.v1Grades)
			Defaults[.gradeTracker] = response.document
			Defaults[.lastServerSync] = .now
		}
		refreshTask = task
		defer { refreshTask = nil }
		try await task.value
	}

	func save(_ document: GradeTrackerDocument) async throws {
		let response: GradeTrackerResponse = try await networkManager.send(
			.v1Grades,
			body: GradeTrackerUpdateRequest(
				document: document,
				serverRevision: Defaults[.gradeTracker].serverRevision
			),
			context: .userInitiated
		)
		Defaults[.gradeTracker] = response.document
	}
}

private extension Endpoint {
	static let v1Grades = Endpoint("/v1/grades")
}
