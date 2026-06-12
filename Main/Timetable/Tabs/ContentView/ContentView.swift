//
//  ContentView.swift
//  Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import Combine
import Defaults
@preconcurrency import EventKit
import SFSafeSymbols
import SwiftUI
#if os(iOS)
import WatchConnectivity
import WidgetKit

enum SyncMode {
	case normal, loading, success, error
}
#endif // os(iOS)

struct SlotConflict {
	let slot: Slot
	let firstClassName: String
	let secondClassName: String
}

enum EditorRequest {
	case allClasses(focus: String?)
	case emptySlot(EditableSlot)
}

enum CalendarImportStatus {
	case loading
	case success
	case error
}

struct ContentView: View {
	@Default(.timetable) var classes
	@Default(.receivedTimetables) var receivedTimetables
	@Environment(\.importedFileURL) private var importedFileURL
	@Environment(\.receivedTimetableData) private var receivedTimetableData

#if os(iOS)
	@State private var watchSync = PhoneWatchSyncBridge()
	@State private var rootSyncStatus = SyncMode.normal
	@State private var pendingSharedTimetable: ReceivedTimetable?
	@State private var importErrorMessage: String?
#endif // os(iOS)

	@State private var selectedTab = 0

	var body: some View {
		TabView(selection: $selectedTab) {
			Tab("Timetable", systemSymbol: .calendar, value: 0) {
#if os(iOS)
				TimetableView(watchSync: $watchSync, syncStatus: $rootSyncStatus)
#else
				TimetableView()
#endif
			}

			Tab("Settings", systemSymbol: .gear, value: 1) {
#if os(iOS)
				SettingsView(watchSync: watchSync, syncStatus: $rootSyncStatus)
#else
				SettingsView()
#endif
			}
		}
#if os(iOS)
		.sheet(item: $pendingSharedTimetable) { timetable in
			SharedTimetableImportSheet(
				timetable: timetable,
				onCancel: {
					pendingSharedTimetable = nil
				},
				onImport: {
					importSharedTimetable(timetable)
				}
			)
			.presentationDetents([.medium, .large])
			.presentationDragIndicator(.visible)
		}
		.onAppear {
			processPendingSharedImport()
		}
		.alert(
			"Could Not Import Timetable",
			isPresented: Binding(
				get: { importErrorMessage != nil },
				set: { newValue in
					if !newValue {
						importErrorMessage = nil
					}
				}
			),
			actions: {
				Button("OK", role: .cancel) {
					importErrorMessage = nil
				}
			},
			message: {
				Text(importErrorMessage ?? "")
			}
		)
		.onChange(of: importedFileURL.wrappedValue) { _, fileURL in
			guard fileURL != nil else { return }
			processPendingSharedImport()
		}
		.onChange(of: receivedTimetableData.wrappedValue) { _, timetableData in
			guard timetableData != nil else { return }
			processPendingSharedImport()
		}
#endif // os(iOS)
		.monospaced()
		.preferredColorScheme(.dark)
	}

#if os(iOS)
	private func importSharedTimetable(_ timetable: ReceivedTimetable) {
		var existing = receivedTimetables
		existing.append(timetable)
		receivedTimetables = existing
		selectedTab = 1
		pendingSharedTimetable = nil
	}

	private func processPendingSharedImport() {
		if let fileURL = importedFileURL.wrappedValue {
			importedFileURL.wrappedValue = nil
			Task {
				await prepareImportPreview(from: fileURL)
			}
			return
		}

		if let timetableData = receivedTimetableData.wrappedValue {
			pendingSharedTimetable = timetableData.receivedTimetable()
			receivedTimetableData.wrappedValue = nil
		}
	}

	private func prepareImportPreview(from fileURL: URL) async {
		let didAccess = fileURL.startAccessingSecurityScopedResource()
		defer {
			if didAccess {
				fileURL.stopAccessingSecurityScopedResource()
			}
		}

		do {
			let data = try await Task.detached(priority: .userInitiated) {
				try Data(contentsOf: fileURL)
			}.value
			let message = try TimetableMessage.decode(data)
			guard !message.timetable.isEmpty else {
				importErrorMessage = "This timetable does not contain any classes."
				return
			}

			pendingSharedTimetable = ReceivedTimetable(
				sender: message.sender,
				classes: message.timetable,
				receivedAt: message.timestamp
			)
		} catch {
			importErrorMessage = error.localizedDescription
		}
	}
#endif // os(iOS)
}

#Preview {
	ContentView()
}
