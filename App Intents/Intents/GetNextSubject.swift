import AppIntents
import Defaults
import SwiftUI

struct GetNextSubjectIntent: SnippetIntent {
	static var title: LocalizedStringResource = "Get Next Subject"
	static var description = IntentDescription("Finds your next scheduled subject today.")
	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

	@MainActor
	func perform() async -> some IntentResult & ProvidesDialog & ReturnsValue<SubjectEntity?> & ShowsSnippetView {
		guard let scheduled = SchoolStateEngine.nextSubject(after: TimetableClock.now, subjects: Defaults[.timetable]) else {
			return .result(value: nil, dialog: "You have no more subjects today.", view: IntentSummaryView(title: "No More Subjects", detail: "There are no scheduled subjects left today."))
		}

		return .result(
			value: scheduled.subject.toSubjectEntity(),
			dialog: "Your next subject is \(scheduled.subject.id) at \(scheduled.interval.start.formatted(date: .omitted, time: .shortened)).",
			view: IntentSummaryView(title: scheduled.subject.id, detail: scheduled.interval.start.formatted(date: .omitted, time: .shortened))
		)
	}
}
