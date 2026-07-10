import AppIntents

struct SchoolDayQuery: EnumerableEntityQuery {
	func allEntities() async -> [SchoolDayEntity] {
		TimetableLayout.fullDayLabels.enumerated().map { SchoolDayEntity(id: $0.offset, name: $0.element) }
	}

	func entities(for identifiers: [Int]) async -> [SchoolDayEntity] {
		await allEntities().filter { identifiers.contains($0.id) }
	}

	func suggestedEntities() async -> [SchoolDayEntity] {
		await allEntities()
	}

	func defaultResult() async -> SchoolDayEntity? {
		let weekday = Calendar.current.component(.weekday, from: TimetableClock.now)
		let index = min((weekday + 5) % 7, 4)
		return SchoolDayEntity(id: index, name: TimetableLayout.fullDayLabels[index])
	}
}
