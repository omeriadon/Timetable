import AppIntents
import Defaults

struct GetNextSubjectIntent: AppIntent {
	static var title: LocalizedStringResource = "Get Next Subject"
	static var description = IntentDescription("Finds your next scheduled subject today.")
	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

	@MainActor
	func perform() async -> some IntentResult & ProvidesDialog & ReturnsValue<SubjectEntity?> {
		guard let scheduled = SchoolStateEngine.nextSubject(after: TimetableClock.now, subjects: Defaults[.timetable]) else {
			return .result(value: nil, dialog: "You have no more subjects today.")
		}

		return .result(
			value: scheduled.subject.toSubjectEntity(),
			dialog: "Your next subject is \(scheduled.subject.id) at \(scheduled.interval.start.formatted(date: .omitted, time: .shortened))."
		)
	}
}
