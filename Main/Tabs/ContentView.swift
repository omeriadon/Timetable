//
//  ContentView.swift
//  Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//


import SwiftUI
#if os(iOS)
	import WatchConnectivity

	enum SyncMode {
		case normal, loading, success, error
	}
#endif // os(iOS)

struct ContentView: View {



	#if os(iOS)
		@State private var watchSync = PhoneWatchSyncBridge()
		@State private var rootSyncStatus = SyncMode.normal

	#endif // os(iOS)

	@State private var selectedTab = 0

	@Binding var expanded: WindowMode

	var body: some View {
		TabView(selection: $selectedTab) {
			Tab("Timetable", systemImage: "calendar", value: 0) {
				#if os(iOS)
					TimetableView(watchSync: $watchSync, syncStatus: $rootSyncStatus)
				#else
					TimetableView(expanded: $expanded)
				#endif
			}

			Tab("Settings", systemImage: "gear", value: 1) {
				#if os(iOS)
					SettingsView(watchSync: watchSync, syncStatus: $rootSyncStatus)
				#else
					SettingsView(expanded: $expanded)
				#endif
			}
		}
		.scrollEdgeEffectStyle(.soft, for: .top)
	}
}

#Preview {
	ContentView(expanded: .constant(.none))
}
