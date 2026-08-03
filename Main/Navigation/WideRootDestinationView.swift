import SwiftUI

struct WideRootDestinationView: View {
	let destination: AppRootDestination
	@Binding var expanded: WindowMode

	var body: some View {
		switch destination {
			case .timetable:
				#if os(iOS)
					TimetableView()
				#else
					TimetableView(expanded: $expanded)
				#endif
			case .friends:
				FriendsView()
			case .settings:
				WideSettingsView()
			case .administration:
				AdministrationView()
		}
	}
}
