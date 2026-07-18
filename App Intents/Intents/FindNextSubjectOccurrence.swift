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
		let inferredPersonID: String
		let inferredSubjectID: String
		if subject.id.hasPrefix("subject.received.") {
			let remainder = subject.id.dropFirst("subject.received.".count)
			let components = remainder.split(separator: ".", maxSplits: 1).map(String.init)
			inferredPersonID = components.first ?? ""
			inferredSubjectID = components.dropFirst().first ?? subject.name
		} else {
			inferredPersonID = PersonTimetableEntity.ownerID
			inferredSubjectID = subject.id.hasPrefix("subject.owner.") ? String(subject.id.dropFirst("subject.owner.".count)) : subject.name
		}
		let timetable = IntentTimetableResolver.resolve(person) ?? IntentTimetableResolver.resolve(personID: inferredPersonID)
		guard let timetable else { return .result(value: nil, dialog: "That timetable is no longer available.", view: IntentSummaryView(title: "Timetable Unavailable", detail: nil)) }
		let subjectName = timetable.subjects.first(where: { $0.id == inferredSubjectID || $0.id == subject.name })?.id ?? subject.name
		guard let occurrence = IntentScheduleHelpers.nextOccurrence(of: subjectName, timetable: timetable, after: TimetableClock.now) else { return .result(value: nil, dialog: "No upcoming occurrence of \(subject.name) was found.", view: IntentSummaryView(title: "No Upcoming Subject", detail: subject.name)) }
		let detail = "\(occurrence.day.name) at \(occurrence.startDate.formatted(date: .omitted, time: .shortened))"
		return .result(value: occurrence, dialog: IntentDialog(stringLiteral: "\(subject.name) is next on \(detail)."), view: IntentSummaryView(title: subject.name, detail: detail))
	}
}
