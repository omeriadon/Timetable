import Combine
import Defaults
import SwiftUI

struct WatchTimetablesTabView: View {
	@Default(.timetable) private var subjects
	@Default(.friends) private var friends
	@Default(.schoolCalendar) private var schoolCalendar
	@State private var now = TimetableClock.now

	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	private var ownerState: SchoolState {
		SchoolStateEngine.calculate(at: now, subjects: subjects, calendar: SchoolCalendarProjection.perthCalendar, schoolCalendar: schoolCalendar)
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

			ForEach(friends) { friend in
				if let timetable = friend.timetable {
					Tab(friend.friend.displayName, systemImage: "person") {
						FriendsTimetablesView(friend: friend, timetable: timetable)
							.background {
								WatchSchoolProgressBackground(
									state: schoolState(for: timetable),
									now: now
								)
								.animation(.smooth, value: schoolState(for: timetable))
								.ignoresSafeArea()
							}
					}
				}
			}
		}
		.monospaced()
		.tabViewStyle(.verticalPage)
		.onReceive(timer) { now = TimetableClock.adjusted($0) }
	}

	private func schoolState(for timetable: FriendTimetable) -> SchoolState {
		SchoolStateEngine.calculate(at: now, subjects: timetable.subjects, calendar: SchoolCalendarProjection.perthCalendar, schoolCalendar: schoolCalendar)
	}
}
