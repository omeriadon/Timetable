import AppIntents
import SwiftUI

struct CompareTimetablesIntent: SnippetIntent {
	static var title: LocalizedStringResource = "Compare Timetables"
	static var description = IntentDescription("Compares two people's teaching sessions for a school day.")
	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
	@Parameter(title: "First Person") var firstPerson: PersonTimetableEntity?
	@Parameter(title: "Second Person") var secondPerson: PersonTimetableEntity?
	@Parameter(title: "Day") var day: SchoolDayEntity?
	@Parameter(title: "Only Shared Free Periods", default: false) var onlySharedFreePeriods: Bool
	static var parameterSummary: some ParameterSummary {
		Summary("Compare \(\.$firstPerson) with \(\.$secondPerson) on \(\.$day)")
	}

	@MainActor
	func perform() async -> some IntentResult & ProvidesDialog & ReturnsValue<[TimetableOverlapEntity]> & ShowsSnippetView {
		let defaultDay = await SchoolDayQuery().defaultResult()
		guard let first = IntentTimetableResolver.resolve(firstPerson), let selectedDay = day ?? defaultDay else { return .result(value: [], dialog: "A timetable or day is unavailable.", view: IntentSummaryView(title: "Selection Unavailable", detail: nil)) }
		let candidates = IntentTimetableResolver.all().filter { !$0.isOwner }
		guard let second = secondPerson.flatMap({ IntentTimetableResolver.resolve($0) }) ?? (candidates.count == 1 ? candidates[0] : nil) else { return .result(value: [], dialog: "Choose a second person to compare.", view: IntentSummaryView(title: "Second Person Required", detail: nil)) }
		guard first.id != second.id else { return .result(value: [], dialog: "Choose two different people.", view: IntentSummaryView(title: "Cannot Compare A Person With Themself", detail: nil)) }
		let firstLookup = TimetableLayout.subjectLookup(for: first.subjects)
		let secondLookup = TimetableLayout.subjectLookup(for: second.subjects)
		let values = SchoolStateEngine.periods.compactMap { period -> TimetableOverlapEntity? in
			guard TimetableLayout.canUse(period: period.number, on: selectedDay.id), let session = TimetableLayout.session(forPeriod: period.number) else { return nil }
			let left = firstLookup[Slot(selectedDay.id, session)]?.id ?? "Free Period"
			let right = secondLookup[Slot(selectedDay.id, session)]?.id ?? "Free Period"
			let bothFree = left == "Free Period" && right == "Free Period"
			guard bothFree || (!onlySharedFreePeriods && left.caseInsensitiveCompare(right) == .orderedSame) else { return nil }
			return TimetableOverlapEntity(id: "overlap.\(first.id).\(second.id).\(selectedDay.id).\(period.number)", firstPerson: first.person, secondPerson: second.person, day: selectedDay, sessionNumber: period.number, firstSubjectName: left, secondSubjectName: right, bothFree: bothFree)
		}
		let shared = values.filter(\.bothFree).count
		return .result(value: values, dialog: IntentDialog(stringLiteral: "\(values.count) matching sessions, including \(shared) shared free periods."), view: IntentListView(title: "\(first.displayName) / \(second.displayName)", values: values.map { "Session \($0.sessionNumber): \($0.firstSubjectName) / \($0.secondSubjectName)" }))
	}
}
