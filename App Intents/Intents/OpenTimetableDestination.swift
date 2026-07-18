import AppIntents
import Foundation
import SwiftUI

struct OpenTimetableDestinationIntent: AppIntent {
	static var title: LocalizedStringResource = "Open Timetable Destination"
	static var description = IntentDescription("Opens a timetable or subject in the app.")
	static var openAppWhenRun = true
	@Parameter(title: "Person") var person: PersonTimetableEntity?
	@Parameter(title: "Subject") var subject: SubjectEntity?
	@Parameter(title: "Day") var day: SchoolDayEntity?
	@Parameter(title: "Session") var session: Int?
	static var parameterSummary: some ParameterSummary {
		Summary("Open \(\.$subject) for \(\.$person)")
	}

	@MainActor
	func perform() async throws -> some IntentResult {
		guard let timetable = IntentTimetableResolver.resolve(person) else { throw NSError(domain: "TimetableIntent", code: 1, userInfo: [NSLocalizedDescriptionKey: "That timetable is no longer available."]) }
		let url: URL = if let subject {
			IntentTimetableResolver.subjectURL(for: timetable, subjectID: subject.name, day: day?.id, session: session.map { $0 - 1 })
		} else {
			IntentTimetableResolver.timetableURL(for: timetable)
		}
		return .result(opensIntent: OpenURLIntent(url))
	}
}
