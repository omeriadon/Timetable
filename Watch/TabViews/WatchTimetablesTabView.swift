import Defaults
import SwiftUI

struct WatchTimetablesTabView: View {
	@Default(.friends) private var friends
	@Default(.timetable) private var subjects

	var body: some View {
		TabView {
			Tab("Timetable", systemImage: "calendar") {
				ContentView()
			}

			if !subjects.isEmpty {
				Tab("Current Subject", systemImage: "timer") {
					CurrentSubjectView()
				}
			}

			ForEach(friends) { friend in
				if let timetable = friend.timetable {
					Tab(friend.friend.displayName, systemImage: "person") {
						FriendsTimetablesView(friend: friend, timetable: timetable)
					}
				}
			}
		}
		.monospaced()
		.tabViewStyle(.verticalPage)
	}
}
