import AppIntents
import SwiftUI

struct GetFreePeriodsIntent: SnippetIntent {
	static var title: LocalizedStringResource = "Get Free Periods"
	static var description = IntentDescription("Lists free teaching periods for a school day.")
	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
	@Parameter(title: "Person") var person: PersonTimetableEntity?
	@Parameter(title: "Day") var day: SchoolDayEntity?
	static var parameterSummary: some ParameterSummary {
		Summary("Show free periods on \(\.$day) for \(\.$person)")
	}

	@MainActor
	func perform() async -> some IntentResult & ProvidesDialog & ReturnsValue<[FreePeriodEntity]> & ShowsSnippetView {
		let defaultDay = await SchoolDayQuery().defaultResult()
		guard let timetable = IntentTimetableResolver.resolve(person), let selectedDay = day ?? defaultDay else { return .result(value: [], dialog: "That timetable is no longer available.", view: IntentSummaryView(title: "Timetable Unavailable", detail: nil)) }
		guard !timetable.subjects.isEmpty else { return .result(value: [], dialog: "No timetable is available.", view: IntentSummaryView(title: "No Timetable", detail: nil)) }
		let values = IntentScheduleHelpers.freePeriods(for: timetable, day: selectedDay.id, date: TimetableClock.now)
		let dialog = values.isEmpty ? "No free periods on \(selectedDay.name)." : "\(values.count) free periods on \(selectedDay.name)."
		return .result(value: values, dialog: IntentDialog(stringLiteral: dialog), view: IntentListView(title: selectedDay.name, values: values.map { "Session \($0.sessionNumber): \($0.startDate.formatted(date: .omitted, time: .shortened))–\($0.endDate.formatted(date: .omitted, time: .shortened))" }))
	}
}
