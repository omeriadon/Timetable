import SwiftUI

struct WideRootDestinationView: View {
	let destination: AppRootDestination

	var body: some View {
		switch destination {
			case .timetable:
				TimetableView()
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
