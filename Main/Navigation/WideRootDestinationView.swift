import SwiftUI

struct WideRootDestinationView: View {
	let destination: AppRootDestination

	var body: some View {
		switch destination {
			case .timetable:
				TimetableView()
			case .friends:
				FriendsView()
			case .settings:
				WideSettingsView()
			case .administration:
				AdministrationView()
		}
	}
}
