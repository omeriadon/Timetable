import Combine
import Defaults
import SwiftUI

struct WatchTimetablesTabView: View {
	@Default(.timetable) private var subjects
	@Default(.receivedTimetables) private var receivedTimetables
	@State private var now = Date()

	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	private var adjustedNow: Date {
		now.addingTimeInterval(debugOffset)
	}

	private var ownerState: SchoolState {
		getSchoolState(
			at: adjustedNow,
			subjectLookup: TimetableLayout.subjectLookup(for: subjects)
		)
	}

	var body: some View {
		TabView {
			Tab("Timetable", systemImage: "calendar") {
				ContentView()
			}

			if !subjects.isEmpty {
				Tab("Current Subject", systemImage: "timer") {
					CurrentSubjectView(now: adjustedNow)
						.containerBackground(for: .tabView) {
							WatchSchoolProgressBackground(state: ownerState, now: adjustedNow)
						}
				}
			}

			ForEach(receivedTimetables) { receivedTimetable in
				Tab(receivedTimetable.sender, systemImage: "person") {
					FriendsTimetablesView(receivedTimetable: receivedTimetable)
						.containerBackground(for: .tabView) {
							WatchSchoolProgressBackground(
								state: schoolState(for: receivedTimetable),
								now: adjustedNow
							)
						}
				}
			}
		}
		.monospaced()
		.tabViewStyle(.verticalPage)
		.onReceive(timer) { now = $0 }
	}

	private func schoolState(for timetable: ReceivedTimetable) -> SchoolState {
		getSchoolState(
			at: adjustedNow,
			subjectLookup: TimetableLayout.subjectLookup(for: timetable.subjects)
		)
	}
}
