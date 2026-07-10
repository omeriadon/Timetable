import AppIntents
import Defaults
import SwiftUI

struct GetTimetableForPersonIntent: SnippetIntent {
	static var title: LocalizedStringResource = "Get Timetable for Person"
	static var description = IntentDescription("Gets your timetable or a received timetable.")
	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

	@Parameter(title: "Person")
	var person: PersonTimetableEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Get \(\.$person)'s timetable")
	}

	@MainActor
	func perform() async -> some IntentResult & ProvidesDialog & ReturnsValue<TimetableEntity?> & ShowsSnippetView {
		let selectedID = person?.id ?? PersonTimetableEntity.ownerID
		if selectedID == PersonTimetableEntity.ownerID {
			let entity = Defaults[.timetable].toTimetableEntity()
			return .result(value: entity, dialog: "Here is your timetable.", view: IntentListView(title: "Your Timetable", values: Defaults[.timetable].map(\.id)))
		}

		guard let timetable = Defaults[.receivedTimetables].first(where: { $0.id == selectedID && !$0.isDeleted }) else {
			return .result(value: nil, dialog: "That timetable is no longer available.", view: IntentSummaryView(title: "Timetable Unavailable", detail: nil))
		}

		return .result(value: timetable.toTimetableEntity(), dialog: "Here is \(timetable.sender)'s timetable.", view: IntentListView(title: "\(timetable.sender)'s Timetable", values: timetable.subjects.map(\.id)))
	}
}
