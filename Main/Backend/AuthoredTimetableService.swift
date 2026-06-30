import Foundation
import Observation

@MainActor
@Observable
final class AuthoredTimetableService {
	static let shared = AuthoredTimetableService()
	private(set) var timetables: [TimetableDetailResponse] = []
	private let network = NetworkManager.shared

	func refresh() async throws {
		do {
			timetables = try await network.send(Endpoint("/v1/timetables/authored"))
		} catch let error as NetworkError where error.suppressesStatusBadge {
			timetables = []
		}
	}

	func update(id: UUID, title: String, subjects: [Subject], isSearchable: Bool) async throws {
		let value: TimetableDetailResponse = try await network.send(Endpoint("/v1/timetables/authored/\(id.uuidString)", method: .put), body: AuthoredTimetableUpdateRequest(title: title, subjects: subjects, isSearchable: isSearchable))
		if let index = timetables.firstIndex(where: { $0.id == id }) { timetables[index] = value }
	}

	func delete(id: UUID) async throws {
		try await network.send(Endpoint("/v1/timetables/authored/\(id.uuidString)", method: .delete))
		timetables.removeAll { $0.id == id }
	}
}
