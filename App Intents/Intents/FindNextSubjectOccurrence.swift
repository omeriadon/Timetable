import AppIntents
import SwiftUI

struct FindNextSubjectOccurrenceIntent: SnippetIntent {
	static var title: LocalizedStringResource = "Find Next Subject Occurrence"
	static var description = IntentDescription("Finds the next scheduled occurrence of a subject.")
	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

	@Parameter(title: "Subject") var subject: SubjectEntity?
	@Parameter(title: "Person") var person: PersonTimetableEntity?
	static var parameterSummary: some ParameterSummary {
		Summary("Find the next occurrence of \(\.$subject)")
	}

	@MainActor
	func perform() async -> some IntentResult & ProvidesDialog & ReturnsValue<ScheduledSubjectEntity?> & ShowsSnippetView {
		guard let subject else { return .result(value: nil, dialog: "Choose a subject.", view: IntentSummaryView(title: "Subject Required", detail: nil)) }
		let inferredID = subject.id.split(separator: ".").dropFirst().dropFirst().dropFirst().joined(separator: ".")
		let timetable = IntentTimetableResolver.resolve(person) ?? IntentTimetableResolver.resolve(personID: subject.id.contains("received.") ? String(subject.id.split(separator: ".")[2]) : PersonTimetableEntity.ownerID)
		guard let timetable else { return .result(value: nil, dialog: "That timetable is no longer available.", view: IntentSummaryView(title: "Timetable Unavailable", detail: nil)) }
		let subjectName = timetable.subjects.first(where: { $0.id == inferredID || $0.id == subject.name })?.id ?? subject.name
		guard let occurrence = IntentScheduleHelpers.nextOccurrence(of: subjectName, timetable: timetable, after: TimetableClock.now) else { return .result(value: nil, dialog: "No upcoming occurrence of \(subject.name) was found.", view: IntentSummaryView(title: "No Upcoming Subject", detail: subject.name)) }
		let detail = "\(occurrence.day.name) at \(occurrence.startDate.formatted(date: .omitted, time: .shortened))"
		return .result(value: occurrence, dialog: IntentDialog(stringLiteral: "\(subject.name) is next on \(detail)."), view: IntentSummaryView(title: subject.name, detail: detail))
	}
}
