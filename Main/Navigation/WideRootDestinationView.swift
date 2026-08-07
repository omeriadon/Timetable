import SwiftUI

struct WideRootDestinationView: View {
	let destination: AppRootDestination

	var body: some View {
		switch destination {
			case .timetable:
				TimetableView()
			case .timetableToday:
				TimetableView(fixedSubtab: .today)
			case .timetableWeek:
				TimetableView(fixedSubtab: .week)
			case .timetablePlanner:
				TimetableView(fixedSubtab: .planner)
			case .friends:
				FriendsView()
			case .grades:
				GradeTrackerView()
			case .settings:
				SettingsView()
			case .administration:
				AdministrationView()
		}
	}
}
