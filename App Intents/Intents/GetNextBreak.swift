import AppIntents
import Defaults
import SwiftUI

struct GetNextBreakIntent: SnippetIntent {
	static var title: LocalizedStringResource = "Get Next Break"
	static var description = IntentDescription("Finds your next recess or lunch today.")
	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

	@MainActor
	func perform() async -> some IntentResult & ProvidesDialog & ReturnsValue<String?> & ShowsSnippetView {
		guard let next = SchoolStateEngine.nextBreak(after: TimetableClock.now, subjects: Defaults[.timetable]) else {
			return .result(value: nil, dialog: "You have no more breaks today.", view: IntentSummaryView(title: "No More Breaks", detail: "There are no scheduled breaks left today."))
		}

		let time = next.interval.start.formatted(date: .omitted, time: .shortened)
		return .result(value: next.type.description, dialog: "Your next break is \(next.type.description) at \(time).", view: IntentSummaryView(title: next.type.description, detail: time))
	}
}
