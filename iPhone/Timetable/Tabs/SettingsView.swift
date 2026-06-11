//
//  SettingsView.swift
//  Timetable
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
	@State private var showEditTimetableSheet = false

	@Namespace private var ns

	var body: some View {
		NavigationStack {
			List {

				Section("Sync to Watch") {
					SyncButton(
						syncStatus: syncStatus,
						action: {
							Task {
								await syncToWatchAsync(
									classes: classes,
									displayMode: displayMode,
									watchSync: watchSync,
									statusUpdate: { syncStatus = $0 }
								)
							}
						}
					)
				}

				Section("Your Details") {
					TextField("Your Name", text: $userDisplayName)
						.submitLabel(.done)
				}

				Section("Your Timetable") {
					Button {
						showEditTimetableSheet = true
					} label: {
						Label {
							Text("Edit Timetable")
						} icon: {
							Image(systemName: "pencil")
								.foregroundStyle(.tint)
						}
					}
					.matchedTransitionSource(id: "sheetMorph", in: ns)
					.sheet(isPresented: $showEditTimetableSheet) {
						ClassEditorSheet(
							classes: $classes,
							initialRequest: nil
						)
						.presentationDetents([.fraction(0.85)])
						.presentationDragIndicator(.hidden)
						.interactiveDismissDisabled()
						.navigationTransition(.zoom(sourceID: "sheetMorph", in: ns))
					}
				}

				Section("Display") {
					HStack {
						Label("watchOS Widget Style", systemImage: "platter.filled.bottom.applewatch.case")
						Spacer()
						Picker("", selection: $displayMode) {
							Label("Symbols", systemImage: "square.grid.2x2")
								.tag(DisplayMode.symbolsOnly)
							Label("Text", systemImage: "text.alignleft")
								.tag(DisplayMode.textOnly)
						}
						.tint(.primary)
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
								.foregroundStyle(.white.secondary)
						} icon: {
							Image(systemName: "calendar")
								.foregroundStyle(.tint)
						}
					}
					.sheet(isPresented: $showCalendarImportSheet) {
						CalendarImportView()
							.presentationDetents([.fraction(1 / 3)])
							.presentationDragIndicator(.hidden)
					}
				}

				if !receivedTimetables.isEmpty {
					importedTimetablesSection
				}

			}
			.scrollEdgeEffectStyle(.soft, for: .top)
			.scrollContentBackground(.hidden)
			.toolbar {
				ToolbarItem(placement: .title) {
					Text("Settings")
						.monospaced()
				}
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
