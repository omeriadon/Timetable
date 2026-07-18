import AppIntents
import Foundation
import SwiftUI

struct GetTimeUntilNextSubjectIntent: SnippetIntent {
	static var title: LocalizedStringResource = "Get Time Until Next Subject"
	static var description = IntentDescription("Reports the time until the next scheduled subject.")
	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
	@Parameter(title: "Person") var person: PersonTimetableEntity?
	static var parameterSummary: some ParameterSummary {
		Summary("Get the time until the next subject for \(\.$person)")
	}

	@MainActor
	func perform() async -> some IntentResult & ProvidesDialog & ReturnsValue<ScheduledSubjectEntity?> & ShowsSnippetView {
		guard let timetable = IntentTimetableResolver.resolve(person) else { return .result(value: nil, dialog: "That timetable is no longer available.", view: IntentSummaryView(title: "Timetable Unavailable", detail: nil)) }
		let now = TimetableClock.now
		guard let occurrence = (0 ... 7).lazy.compactMap({ offset -> ScheduledSubjectEntity? in
			guard let date = Calendar.current.date(byAdding: .day, value: offset, to: now) else { return nil }
			let weekday = Calendar.current.component(.weekday, from: date)
			guard (2 ... 6).contains(weekday) else { return nil }
			return IntentScheduleHelpers.occurrences(for: timetable, day: weekday - 2, date: date).first(where: { $0.startDate > now })
		}).first else {
			let title = timetable.subjects.isEmpty ? "No Timetable" : "No More Subjects"
			return .result(value: nil, dialog: IntentDialog(stringLiteral: timetable.subjects.isEmpty ? "No timetable is available." : "There are no more subjects in the next seven days."), view: IntentSummaryView(title: title, detail: nil))
		}
		let seconds = max(0, occurrence.startDate.timeIntervalSince(now))
		let minutes = Int(seconds / 60)
		return .result(value: occurrence, dialog: IntentDialog(stringLiteral: "\(occurrence.subject.name) starts in \(minutes) minutes."), view: IntentSummaryView(title: occurrence.subject.name, detail: "Starts \(occurrence.startDate.formatted(date: .omitted, time: .shortened)) — \(minutes) minutes"))
	}
}
