import AppIntents

nonisolated struct SchoolDayEntity: AppEntity, Identifiable {
	static let defaultQuery = SchoolDayQuery()
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "School Day")

	let id: Int
	let name: String

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(title: "\(name)")
	}
}
