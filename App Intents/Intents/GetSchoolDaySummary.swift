import AppIntents
import Defaults
import SwiftUI

struct GetSchoolDaySummaryIntent: SnippetIntent {
	static var title: LocalizedStringResource = "Get School Day Summary"
	static var description = IntentDescription("Summarizes the scheduled subjects and free periods for a school day.")
	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

	@Parameter(title: "Person") var person: PersonTimetableEntity?
	@Parameter(title: "Day") var day: SchoolDayEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Summarize \(\.$day) for \(\.$person)")
	}

	@MainActor
	func perform() async -> some IntentResult & ProvidesDialog & ReturnsValue<[ScheduledSubjectEntity]> & ShowsSnippetView {
		let defaultDay = await SchoolDayQuery().defaultResult()
		guard let timetable = IntentTimetableResolver.resolve(person), let selectedDay = day ?? defaultDay else { return .result(value: [], dialog: "That timetable is no longer available.", view: IntentSummaryView(title: "Timetable Unavailable", detail: nil)) }
		let values = IntentScheduleHelpers.occurrences(for: timetable, day: selectedDay.id, date: TimetableClock.now)
		let free = IntentScheduleHelpers.freePeriods(for: timetable, day: selectedDay.id, date: TimetableClock.now)
		let title = values.isEmpty ? (timetable.subjects.isEmpty ? "No Timetable" : "No Lessons") : selectedDay.name
		let dialog = values.isEmpty ? (timetable.subjects.isEmpty ? "There is no timetable for \(timetable.displayName)." : "There are no lessons on \(selectedDay.name).") : "\(values.count) lessons on \(selectedDay.name), with \(free.count) free periods."
		let rows = (values.map { "\($0.sessionNumber). \($0.subject.name) — \($0.startDate.formatted(date: .omitted, time: .shortened))" } + free.map { "\($0.sessionNumber). Free Period — \($0.startDate.formatted(date: .omitted, time: .shortened))" }).sorted()
		return .result(value: values, dialog: IntentDialog(stringLiteral: dialog), view: IntentListView(title: title, values: rows))
	}
}
