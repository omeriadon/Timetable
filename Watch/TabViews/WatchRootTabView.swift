import Defaults
import SwiftUI

struct WatchRootTabView: View {
	@Default(.accountSettings) private var accountSettings

	var body: some View {
		TabView {
			Tab("Timetables", systemImage: "circle.fill") {
				WatchTimetablesTabView()
			}

			Tab("Settings", systemImage: "circle.fill") {
				WatchSettingsView()
			}
		}
		.fontDesign(accountSettings.appFontDesign.swiftUIFontDesign)
	}
}
