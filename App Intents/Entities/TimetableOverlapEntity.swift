import AppIntents

struct TimetableOverlapEntity: AppEntity, Identifiable {
	static var defaultQuery = TimetableOverlapQuery()
	static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Timetable Comparison")

	let id: String
	let firstPerson: PersonTimetableEntity
	let secondPerson: PersonTimetableEntity
	let day: SchoolDayEntity
	let sessionNumber: Int
	let firstSubjectName: String
	let secondSubjectName: String
	let bothFree: Bool

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(title: "Session \(sessionNumber)", subtitle: "\(firstSubjectName) / \(secondSubjectName)")
	}
}

struct TimetableOverlapQuery: EntityQuery {
	func entities(for _: [String]) async throws -> [TimetableOverlapEntity] {
		[]
	}
}
