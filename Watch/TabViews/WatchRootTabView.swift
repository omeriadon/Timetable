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
		.tabViewStyle(.page)
		.indexViewStyle(.page(backgroundDisplayMode: .never))
		.ignoresSafeArea(.container, edges: .vertical)
		.fontDesign(accountSettings.appFontDesign.swiftUIFontDesign)
	}
}
