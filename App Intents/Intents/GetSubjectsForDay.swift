import AppIntents
import Defaults

struct GetSubjectsForDayIntent: AppIntent {
	static var title: LocalizedStringResource = "Get Subjects for Day"
	static var description = IntentDescription("Lists your scheduled subjects for a school day.")
	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

	@Parameter(title: "Day")
	var day: SchoolDayEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Get subjects for \(\.$day)")
	}

	@MainActor
	func perform() async -> some IntentResult & ProvidesDialog & ReturnsValue<[SubjectEntity]> {
		let defaultDay = await SchoolDayQuery().defaultResult()
		let selectedDay = day ?? defaultDay ?? SchoolDayEntity(id: 0, name: "Monday")
		let subjects = SchoolStateEngine.subjects(onDayIndex: selectedDay.id, from: Defaults[.timetable])
		let dialog = subjects.isEmpty
			? "You have no subjects on \(selectedDay.name)."
			: "You have \(subjects.count) subjects on \(selectedDay.name)."
		return .result(value: subjects.toSubjectEntities(), dialog: IntentDialog(stringLiteral: dialog))
	}
}
