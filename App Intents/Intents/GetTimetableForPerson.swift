import AppIntents
import Defaults
import SwiftUI

struct GetTimetableForPersonIntent: SnippetIntent {
	static var title: LocalizedStringResource = "Get Timetable for Person"
	static var description = IntentDescription("Gets your timetable.")
	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

	@Parameter(title: "Person")
	var person: PersonTimetableEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Get \(\.$person)'s timetable")
	}

	@MainActor
	func perform() async -> some IntentResult & ProvidesDialog & ReturnsValue<TimetableEntity?> & ShowsSnippetView {
		let entity = Defaults[.timetable].toTimetableEntity()
		return .result(value: entity, dialog: "Here is your timetable.", view: IntentListView(title: "Your Timetable", values: Defaults[.timetable].map(\.id)))
	}
}
