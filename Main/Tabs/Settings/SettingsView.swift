//
//   SettingsView.swift
//   Main
//
//   Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SwiftUI
import WidgetKit
#if os(iOS)
	import WatchConnectivity
#endif

struct RenameTimetable: Identifiable {
	let id: String
	let timetable: ReceivedTimetable
}

struct SettingsView: View {
	@Default(.timetable) var subjects

	@Environment(\.passManager) private var passManager
	@Environment(\.statusBadgeManager) private var statusBadgeManager
	@State private var sessionStore = SessionStore.shared

	#if os(iOS)
		let watchSync: PhoneWatchSyncBridge

		@Binding var syncStatus: SyncMode

	#else
		@Binding var expanded: WindowMode
	#endif

	@State private var showCalendarImportSheet = false
	@State private var showEditTimetableSheet = false
	@State private var ownerIsSearchable = Defaults[.ownerIsSearchable]
	@State private var committedOwnerIsSearchable = Defaults[.ownerIsSearchable]
	@State private var visibilitySaveGeneration = 0
	@State private var showEditReceivedTimetablesSheet = false

	@Namespace private var ns

	#if os(iOS)
		init(watchSync: PhoneWatchSyncBridge, syncStatus: Binding<SyncMode>) {
			self.watchSync = watchSync
			_syncStatus = syncStatus
		}
	#else
		init(expanded: Binding<WindowMode>) {
			_expanded = expanded
		}
	#endif

	var body: some View {
		NavigationStack {
			Group {
				#if os(iOS)
					List {
						list
					}
					.listStyle(.sidebar)

				#else
					Form {
						list
					}
					.scrollEdgeEffectStyle(.soft, for: .top)
					.formStyle(.grouped)
				#endif
			}
			.scrollEdgeEffectStyle(.soft, for: .top)
			.scrollContentBackground(.hidden)
			.appNavigationTitle("Settings", style: .main)
		}
		#if os(macOS)
		.onAppear { expanded = .settings }
		.onDisappear { expanded = .none }
		#endif
	}

	@ContentBuilder
	private var list: some View {
		Section("Account") {
			NavigationLink {
				AccountView()
			} label: {
				Label("Account", systemImage: "person.crop.circle")
			}
		}

		Section("Preferences") {
			NavigationLink {
				AccountAndSyncSettingsView()
			} label: {
				Label("Preferences", systemImage: "switch.2")
			}
		}

		#if os(iOS)

			Section("Sync") {
				Menu {
					Button {
						Task { await ServerSyncCoordinator.shared.syncEverything() }
					} label: {
						Label("Cloud", systemImage: "cloud")
					}

					Button {
						if !WCSession.default.isWatchAppInstalled {
							statusBadgeManager.addBadge(id: UUID(), title: "Watch app not installed", priority: 4, view: .warning)
							return
						}

						Task {
							await syncToWatchAsync(
								subjects: subjects,
								watchSync: watchSync,
								statusUpdate: { syncStatus = $0 }
							)
						}
					} label: {
						Label("Watch", systemImage: "applewatch")
					}
					.disabled(syncStatus == .loading)

				} label: {
					Label("Sync to...", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
				}
			}

			Section("Your Timetable") {
				Toggle("Searchable", isOn: ownerVisibilityBinding)
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
					SubjectEditorSheet(
						subjects: $subjects,
						initialRequest: nil,
						onSave: { ServerSyncCoordinator.shared.ownerTimetableChanged() }
					)
					.presentationDetents([.fraction(0.85)])
					.presentationDragIndicator(.hidden)
					.interactiveDismissDisabled()
					.navigationTransition(.zoom(sourceID: "sheetMorph", in: ns))
				}
			}

			Section("Authored Timetables") {
				if sessionStore.isAuthenticated {
					NavigationLink { AuthoredTimetablesSettingsView() } label: { Label("Manage Authored Timetables", systemImage: "person.2.crop.square.stack") }
				} else {
					Button { showSignInRequired() } label: { Label("Manage Authored Timetables", systemImage: "person.2.crop.square.stack") }
				}
			}

			Section("Add Timetable to Wallet") {
				AddPassView()
			}

			Section("Calendar") {
				Button {
					showCalendarImportSheet = true
				} label: {
					HStack(alignment: .center) {
						Image(systemName: "calendar")
							.foregroundStyle(.tint)
							.imageScale(.large)
							.padding(.trailing, 10)

						VStack(alignment: .leading) {
							Text("Import from Calendar")
								.foregroundStyle(.accent)
							Text("Subscribe to Compass Schedule in Calendar")
								.foregroundStyle(.secondary)
								.font(.callout)
						}
					}
				}
				.sheet(isPresented: $showCalendarImportSheet) {
					CalendarImportView()
						.presentationDetents([.fraction(1 / 3)])
						.presentationDragIndicator(.hidden)
				}
			}

			if !passManager.receivedTimetables.isEmpty {
				Section("Imported Timetables") {
					Button {
						showEditReceivedTimetablesSheet = true
					} label: {
						Label("Edit Received Timetables...", systemImage: "calendar")
					}
					.matchedTransitionSource(id: "unique_transition_id", in: ns)
					.sheet(isPresented: $showEditReceivedTimetablesSheet) {
						ReceivedTimetablesView()
							.presentationDetents([.fraction(0.8)])
							.presentationDragIndicator(.hidden)
						#if os(iOS)
							.navigationTransition(
								.zoom(sourceID: "unique_transition_id", in: ns)
							)
						#else
							.frame(width: 600, height: 500)
						#endif
					}
					.onChange(of: passManager.receivedTimetables) { _, newValue in
						if newValue.isEmpty {}
					}
				}
			}
		#endif // os(iOS)

		Section("Developer") {
			#if DEBUG
				Button("Test progress badge", systemImage: "progress.indicator") {
					addDebugStatusBadge(title: "Syncing account", secondaryText: "Working", view: .progressView)
				}
				Button("Test success badge", systemImage: "checkmark.circle") {
					addDebugStatusBadge(title: "Saving timetable", view: .success)
				}
				Button("Test error badge", systemImage: "xmark.circle") {
					addDebugStatusBadge(title: "Contacting server", view: .error)
				}
				Button("Test warning badge", systemImage: "exclamationmark.triangle") {
					addDebugStatusBadge(title: "Checking timetable", view: .warning)
				}
				Button("Test progress and gauge badge", systemImage: "arrow.trianglehead.2.clockwise.rotate.90") {
					Task {
						let id = UUID()
						statusBadgeManager.addBadge(id: id, title: "Preparing Wallet pass", priority: 3, view: .progressViewAndGauge(currentStep: 1, totalSteps: 3))

						try? await Task.sleep(for: .seconds(1))

						statusBadgeManager.updateBadge(id: id, title: "Preparing Wallet pass", view: .progressViewAndGauge(currentStep: 2, totalSteps: 3))

						try? await Task.sleep(for: .seconds(1))

						statusBadgeManager.updateBadge(id: id, title: "Preparing Wallet pass", view: .progressViewAndGauge(currentStep: 3, totalSteps: 3))

						try? await Task.sleep(for: .seconds(1))

						statusBadgeManager.updateBadge(id: id, title: "Prepared Wallet pass", view: .success)
					}
				}
			#endif // DEBUG

			Button {
				WidgetCenter.shared.reloadAllTimelines()
				statusBadgeManager.addBadge(id: UUID(), title: "Widgets reloaded", priority: 3, view: .success)
			} label: {
				Label("Reload widgets now", systemImage: "widget.extralarge")
					.foregroundStyle(.accent)
			}
		}
	}

	private var ownerVisibilityBinding: Binding<Bool> {
		Binding(
			get: { ownerIsSearchable },
			set: { value in
				guard sessionStore.isAuthenticated else {
					ownerIsSearchable = committedOwnerIsSearchable
					showSignInRequired()
					return
				}

				visibilitySaveGeneration += 1
				let generation = visibilitySaveGeneration
				let previous = committedOwnerIsSearchable
				ownerIsSearchable = value
				Task { await saveOwnerVisibility(value, previous: previous, generation: generation) }
			}
		)
	}

	private func saveOwnerVisibility(_ proposed: Bool, previous: Bool, generation: Int) async {
		do {
			let committed = try await OwnerTimetableSyncService.shared.updateVisibility(proposed)
			guard generation == visibilitySaveGeneration else { return }
			ownerIsSearchable = committed
			committedOwnerIsSearchable = committed
			statusBadgeManager.addBadge(id: UUID(), title: "Visibility updated", priority: 3, view: .success)
		} catch {
			guard generation == visibilitySaveGeneration else { return }
			ownerIsSearchable = previous
			statusBadgeManager.addBadge(id: UUID(), title: "Unable to update visibility", secondaryText: error.localizedDescription, priority: 4, view: .error)
		}
	}

	#if DEBUG
		private func addDebugStatusBadge(title: String, secondaryText: String? = nil, view: StatusBadgeView) {
			let id = UUID()
			statusBadgeManager.addBadge(id: id, title: title, secondaryText: secondaryText, priority: 3, view: view)

			Task {
				try? await Task.sleep(for: .seconds(4))
				statusBadgeManager.updateBadge(id: id, title: "Done", view: .success)
			}
		}
	#endif // DEBUG

	private func showSignInRequired() {
		statusBadgeManager.addBadge(id: UUID(), title: "Sign in required", secondaryText: "Sign in to use this feature.", priority: 3, view: .warning)
	}
}

extension Array {
	mutating func apply(
		difference: ReorderDifference<Element.ID, some Hashable & Sendable>
	) where Element: Identifiable, Element.ID: Sendable {
		// Find the source card that moved.
		guard let sourceIndex = firstIndex(
			where: { $0.id == difference.sources[0] }
		)
		else { return }
		let movedCard = remove(at: sourceIndex)

		// Find the destination of that card.
		var destination: Int
		switch difference.destination.position {
			case let .before(value):
				guard let index = firstIndex(where: { $0.id == value })
				else { return }
				destination = index
			case .end:
				destination = endIndex
		}
		insert(movedCard, at: destination)
	}
}
