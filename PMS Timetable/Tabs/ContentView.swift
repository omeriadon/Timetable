//
//  ContentView.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import Combine
import Defaults
@preconcurrency import EventKit
import SFSafeSymbols
import SwiftUI
import WatchConnectivity
import WidgetKit

enum SyncMode {
	case normal, loading, success, error
}

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

	@StateObject private var watchSync = PhoneWatchSyncBridge()

	@State private var selectedTab = 0
	@State private var pendingSharedTimetable: ReceivedTimetable?
	@State private var importErrorMessage: String?

	@State private var rootSyncStatus = SyncMode.normal

	var body: some View {
		TabView(selection: $selectedTab) {
			Tab("Timetable", systemSymbol: .calendar, value: 0) {
				TimetableView(watchSync: watchSync, syncStatus: $rootSyncStatus)
			}

			Tab("Settings", systemSymbol: .gear, value: 1) {
				SettingsView(watchSync: watchSync, syncStatus: $rootSyncStatus)
			}
		}
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
	}

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
}

struct SharedTimetableImportSheet: View {
	let timetable: ReceivedTimetable
	let onCancel: () -> Void
	let onImport: () -> Void

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					VStack(alignment: .leading, spacing: 8) {
						Text(timetable.sender)
							.font(.headline)
						Text("\(timetable.classes.count) classes shared")
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					.frame(maxWidth: .infinity, alignment: .leading)

					TimetableGridPreview(
						classes: timetable.classes,
						showsTitle: false
					)
					.clipShape(RoundedRectangle(cornerRadius: 16))
				}
				.padding()
			}
			.navigationTitle("Import Timetable")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel", action: onCancel)
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Import", action: onImport)
						.buttonStyle(.glassProminent)
				}
			}
		}
		.monospaced()
	}
}

#Preview {
	ContentView()
}
