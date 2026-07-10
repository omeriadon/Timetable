import AppIntents

nonisolated struct PersonTimetableEntity: AppEntity, Identifiable {
	static let ownerID = "owner"
	static let defaultQuery = PersonTimetableQuery()
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Person")

	let id: String
	let displayName: String

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(title: "\(displayName)")
	}
}
