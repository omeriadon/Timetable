import Defaults
import Foundation
import Observation

@MainActor
@Observable
final class AuthoredTimetableService {
	static let shared = AuthoredTimetableService()
	var timetables = Defaults[.authoredTimetables]
	private let network = NetworkManager.shared

	func refresh() async throws {
		do {
			try await apply(network.send(Endpoint("/v1/timetables/authored")))
		} catch let error as NetworkError where error.suppressesStatusBadge {
			return
		}
	}

	func update(id: UUID, title: String, subjects: [Subject], isSearchable: Bool) async throws {
		try Platform.require(Platform.current.allowsAuthoredTimetableMutation)
		let value: TimetableDetailResponse = try await network.send(Endpoint("/v1/timetables/authored/\(id.uuidString)", method: .put), body: AuthoredTimetableUpdateRequest(title: title, subjects: subjects, isSearchable: isSearchable))
		if let index = timetables.firstIndex(where: { $0.id == id }) {
			timetables[index] = value
		} else {
			timetables.append(value)
		}
		timetables.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
		Defaults[.authoredTimetables] = timetables
	}

	@discardableResult
	func create(title: String, subjects: [Subject], isSearchable: Bool) async throws -> TimetableDetailResponse {
		try Platform.require(Platform.current.allowsAuthoredTimetableMutation)
		let value: TimetableDetailResponse = try await network.send(
			Endpoint("/v1/timetables/authored", method: .post),
			body: AuthoredTimetableUpdateRequest(title: title, subjects: subjects, isSearchable: isSearchable)
		)
		timetables.append(value)
		timetables.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
		Defaults[.authoredTimetables] = timetables
		return value
	}

	func delete(id: UUID) async throws {
		try Platform.require(Platform.current.allowsAuthoredTimetableMutation)
		try await network.send(Endpoint("/v1/timetables/authored/\(id.uuidString)", method: .delete))
		timetables.removeAll { $0.id == id }
		Defaults[.authoredTimetables] = timetables
	}

	private func apply(_ timetables: [TimetableDetailResponse]) {
		self.timetables = timetables.sorted {
			$0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
		}
		Defaults[.authoredTimetables] = self.timetables
	}
}
