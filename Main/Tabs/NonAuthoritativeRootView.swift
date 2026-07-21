import SwiftUI

struct NonAuthoritativeRootView: View {
	@Binding var expanded: WindowMode

	#if os(iOS)
		@State private var watchSync = PhoneWatchSyncBridge.shared
		@State private var syncStatus = SyncMode.normal
	#endif
	@State private var selectedTab = 0

	init(expanded: Binding<WindowMode>) {
		_expanded = expanded
	}

	var body: some View {
		TabView(selection: $selectedTab) {
			Tab("Timetable", systemImage: "calendar", value: 0) {
				#if os(iOS)
					TimetableView(watchSync: $watchSync, syncStatus: $syncStatus)
				#else
					TimetableView(expanded: $expanded)
				#endif
			}
			Tab("Settings", systemImage: "gear", value: 1) {
				NonAuthoritativeSettingsView(expanded: $expanded)
			}
		}
		#if os(iOS)
		.frame(minWidth: 900, minHeight: 600)
		#endif
	}
}
