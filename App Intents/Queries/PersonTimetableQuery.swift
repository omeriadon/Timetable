import AppIntents
import Defaults

struct PersonTimetableQuery: EntityStringQuery {
	func entities(for identifiers: [String]) async -> [PersonTimetableEntity] {
		await MainActor.run {
			allEntities().filter { identifiers.contains($0.id) }
		}
	}

	func entities(matching string: String) async -> [PersonTimetableEntity] {
		await MainActor.run {
			allEntities().filter { $0.displayName.localizedCaseInsensitiveContains(string) }
		}
	}

	func suggestedEntities() async -> [PersonTimetableEntity] {
		await MainActor.run { allEntities() }
	}

	func defaultResult() async -> PersonTimetableEntity? {
		PersonTimetableEntity(id: PersonTimetableEntity.ownerID, displayName: "You")
	}

	@MainActor
	private func allEntities() -> [PersonTimetableEntity] {
		let owner = PersonTimetableEntity(id: PersonTimetableEntity.ownerID, displayName: "You")
		let received = Defaults[.receivedTimetables]
			.filter { !$0.isDeleted }
			.map { PersonTimetableEntity(id: $0.id, displayName: $0.sender) }
		return [owner] + received
	}
}
