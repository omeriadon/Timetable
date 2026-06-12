//
//  SettingsView.swift
//  Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SwiftUI
#if os(iOS)
import WidgetKit
#endif

struct SettingsView: View {
	@Default(.timetable) var classes
	@Default(.receivedTimetables) var receivedTimetables

	@Default(.userDisplayName) var userDisplayName
	@State private var username: String

#if os(iOS)
	let watchSync: PhoneWatchSyncBridge

	@Binding var syncStatus: SyncMode
#endif

	@State private var showCalendarImportSheet = false
	@State private var timetableToDelete: ReceivedTimetable?
	@State private var showDeleteConfirmation = false
	@State private var showEditTimetableSheet = false

	@Namespace private var ns

#if os(iOS)
	init(watchSync: PhoneWatchSyncBridge, syncStatus: Binding<SyncMode>) {
		_username = State(initialValue: Defaults[.userDisplayName])

		self.watchSync = watchSync
		self._syncStatus = syncStatus
	}
#else
	init() {
		_username = State(initialValue: Defaults[.userDisplayName])
	}
#endif

	var body: some View {
		NavigationStack {
			List {
#if os(iOS)
				Section("Sync to Watch") {
					SyncButton(
						syncStatus: syncStatus,
						action: {
							Task {
								await syncToWatchAsync(
									classes: classes,
									watchSync: watchSync,
									statusUpdate: { syncStatus = $0 }
								)
							}
						}
					)
				}
#endif // os(iOS)

				Section("Your Details") {
					TextField("Your Name", text: $username)
						.submitLabel(.done)
				}
				.onChange(of: username) {
					Defaults[.userDisplayName] = username
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
#if os(iOS)
							.navigationTransition(.zoom(sourceID: "sheetMorph", in: ns))
#endif
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
#if os(iOS)
				ToolbarItem(placement: .title) {
					Text("Settings")
						.monospaced()
				}
#else
				ToolbarItem(placement: .navigation) {
					Text("Settings")
						.monospaced()
				}
#endif
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
