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
			let text = string.trimmingCharacters(in: .whitespacesAndNewlines)
			guard !text.isEmpty else { return allEntities() }
			return allEntities().filter { $0.displayName.localizedCaseInsensitiveContains(text) }
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
		IntentTimetableResolver.all().map(\.person)
	}
}
