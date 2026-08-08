import Defaults
import SwiftUI

struct WatchRootTabView: View {
	@Default(.accountSettings) private var accountSettings

	var body: some View {
		TabView {
			Tab(value: 0) {
				WatchTimetablesTabView()
			} label: {
				Label("Timetables", systemImage: "circle.fill")
					.fontDesign(accountSettings.appFontDesign.swiftUIFontDesign)
			}

			Tab(value: 1) {
				WatchSettingsView()
			} label: {
				Label("Settings", systemImage: "circle.fill")
					.fontDesign(accountSettings.appFontDesign.swiftUIFontDesign)
			}
		}
		.tabViewStyle(.page)
	}
}
