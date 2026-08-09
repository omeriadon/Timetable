import Defaults
import SwiftUI

struct FriendsTimetablesView: View {
	let friend: FriendSummary
	let timetable: FriendTimetable
	@Default(.schoolCalendar) private var schoolCalendar

	var body: some View {
		WatchTimetableView(
			subjects: timetable.subjects,
			displayName: friend.friend.displayName,
			schoolCalendar: schoolCalendar
		)
	}
}
