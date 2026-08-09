import Defaults
import SwiftUI

struct FriendsTimetablesView: View {
	let friend: FriendSummary
	let timetable: FriendTimetable
	@Default(.schoolCalendar) private var schoolCalendar

	var body: some View {
		WatchTimetableView(
			subjects: timetable.subjects,
			schoolCalendar: schoolCalendar
		)
	}
}

struct CurrentSubjectView: View {
	@Default(.timetable) private var subjects
	@Default(.schoolCalendar) private var schoolCalendar

	var body: some View {
		WatchTimetableView(
			subjects: subjects,
			schoolCalendar: schoolCalendar,
			shorter: true
		)
	}
}
