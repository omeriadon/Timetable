import SwiftUI

struct MessagesRootView: View {
	var body: some View {
		ContentUnavailableView(
			"Timetable Sharing Removed",
			systemImage: "calendar.badge.xmark",
			description: Text("Timetables are no longer shared through Messages.")
		)
		.monospaced()
	}
}
