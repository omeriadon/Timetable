import SwiftUI

struct WatchRootTabView: View {
	var body: some View {
		TabView {
			Tab("Timetables", systemImage: "calendar") {
				WatchTimetablesTabView()
			}

			Tab("Settings", systemImage: "gear") {
				WatchSettingsView()
			}
		}
		.tabViewStyle(.page)
	}
}
