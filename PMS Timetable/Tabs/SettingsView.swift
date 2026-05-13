//
//  SettingsView.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct SettingsView: View {
	@Default(.timetable) var classes
	@Default(.displayMode) var displayMode
	@Default(.userDisplayName) var userDisplayName
	@Default(.receivedTimetables) var receivedTimetables

	let watchSync: PhoneWatchSyncBridge

	@Binding var syncStatus: SyncMode

	@State private var showCalendarImportSheet = false
	@State private var timetableToDelete: ReceivedTimetable?
	@State private var showDeleteConfirmation = false

	var body: some View {
		NavigationStack {
			List {
				Section("Your Details") {
					TextField("Your Name", text: $userDisplayName)
				}

				Section("Display") {
					HStack {
						Label("watchOS Widget Style", systemImage: "platter.filled.bottom.applewatch.case")
						Spacer()
						Picker("", selection: $displayMode) {
							Label("Symbols", systemImage: "square.grid.2x2")
								.labelIconToTitleSpacing(30)
								.tag(DisplayMode.symbolsOnly)
							Label("Text", systemImage: "text.alignleft")
								.labelIconToTitleSpacing(30)
								.tag(DisplayMode.textOnly)
						}
						.pickerStyle(.menu)
						.onChange(of: displayMode) { _, _ in
							WidgetCenter.shared.reloadAllTimelines()

							Task {
								await syncToWatchAsync(
									classes: classes,
									displayMode: displayMode,
									watchSync: watchSync,
									statusUpdate: { syncStatus = $0 }
								)
							}
						}
					}
				}

				Section("Calendar") {
					Button {
						showCalendarImportSheet = true
					} label: {
						Label {
							Text("Import Calendar")
								.foregroundStyle(.tint)
							Text("Subscribe to Compass Schedule in Calendar")
								.foregroundStyle(.primary.secondary)
						} icon: {
							Image(systemName: "calendar")
								.foregroundStyle(.tint)
						}
					}
				}

				if !receivedTimetables.isEmpty {
					importedTimetablesSection
				}
			}
			.scrollContentBackground(.hidden)
			.toolbar {
				ToolbarItem(placement: .title) {
					Text("Settings")
						.monospaced()
				}
			}
			.sheet(isPresented: $showCalendarImportSheet) {
				CalendarImportView()
					.presentationDetents([.fraction(1 / 3)])
					.presentationDragIndicator(.hidden)
			}
			.alert("Delete Timetable?", isPresented: $showDeleteConfirmation, presenting: timetableToDelete) { timetable in
				Button("Cancel", role: .cancel) {}
				Button("Delete", role: .destructive) {
					receivedTimetables.removeAll { $0.id == timetable.id }
				}
			} message: { timetable in
				Text("Are you sure you want to delete \(timetable.sender)'s timetable?")
			}
		}
	}

	private var importedTimetablesSection: some View {
		Section("Imported Timetables") {
			ForEach(receivedTimetables) { timetable in
				VStack(alignment: .leading, spacing: 4) {
					Text(timetable.sender)
						.font(.headline)
					Text("\(timetable.classes.count) classes")
						.font(.caption)
						.foregroundStyle(.secondary)
					Text("Received: \(timetable.receivedAt.formatted(date: .abbreviated, time: .omitted))")
						.font(.caption2)
						.foregroundStyle(.secondary)
				}
				.listRowBackground(Rectangle().fill(.ultraThinMaterial))
			}
			.onDelete { indexSet in
				for index in indexSet {
					let timetable = receivedTimetables[index]
					timetableToDelete = timetable
					showDeleteConfirmation = true
				}
			}
		}
	}
}
