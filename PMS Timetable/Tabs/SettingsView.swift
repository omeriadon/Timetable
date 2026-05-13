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
							Text("Subscribe to Compass Schedule in Calendar")
								.foregroundStyle(.secondary)
						} icon: {
							Image(systemName: "calendar")
						}
					}
				}

				if !receivedTimetables.isEmpty {
					importedTimetablesSection
				}
			}
			.foregroundStyle(.primary)
			.scrollContentBackground(.hidden)
			.navigationBarTitleDisplayMode(.inline)
			.navigationTitle("Settings")
			.sheet(isPresented: $showCalendarImportSheet) {
				CalendarImportView()
					.presentationDetents([.fraction(1 / 3)])
					.presentationDragIndicator(.hidden)
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
		}
	}
}
