import SwiftUI

struct WatchRootTabView: View {
	var body: some View {
		TabView {
			Tab("Timetables", systemImage: "circle.fill") {
				WatchTimetablesTabView()
			}

			Tab("Settings", systemImage: "circle.fill") {
				WatchSettingsView()
			}
		}
		.tabViewStyle(.page)
	}
}
