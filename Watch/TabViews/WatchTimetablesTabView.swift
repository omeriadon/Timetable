import Combine
import Defaults
import SwiftUI

struct WatchTimetablesTabView: View {
	@Default(.timetable) private var subjects
	@Default(.receivedTimetables) private var receivedTimetables
	@State private var now = TimetableClock.now

	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	private var ownerState: SchoolState {
		SchoolStateEngine.calculate(at: now, subjects: subjects)
	}

	var body: some View {
		TabView {
			Tab("Timetable", systemImage: "calendar") {
				ContentView()
			}

			if !subjects.isEmpty {
				Tab("Current Subject", systemImage: "timer") {
					CurrentSubjectView(now: now)
						.background {
							WatchSchoolProgressBackground(state: ownerState, now: now)
								.animation(.smooth, value: ownerState)
								.ignoresSafeArea()
						}
				}
			}

			ForEach(receivedTimetables) { receivedTimetable in
				Tab(receivedTimetable.sender, systemImage: "person") {
					FriendsTimetablesView(receivedTimetable: receivedTimetable)
						.background {
							WatchSchoolProgressBackground(
								state: schoolState(for: receivedTimetable),
								now: now
							)
							.animation(.smooth, value: schoolState(for: receivedTimetable))
							.ignoresSafeArea()
						}
				}
			}
		}
		.monospaced()
		.tabViewStyle(.verticalPage)
		.onReceive(timer) { now = TimetableClock.adjusted($0) }
	}

	private func schoolState(for timetable: ReceivedTimetable) -> SchoolState {
		SchoolStateEngine.calculate(at: now, subjects: timetable.subjects)
	}
}
