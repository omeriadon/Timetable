//
//   SettingsView.swift
//   Main
//
//   Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct RenameTimetable: Identifiable {
	let id: String
	let timetable: ReceivedTimetable
}

struct SettingsView: View {
	@Default(.timetable) var subjects

	@Environment(\.passManager) private var passManager
	@Environment(\.statusBadgeManager) private var statusBadgeManager

	@Default(.userDisplayName) var userDisplayName
	@State private var username: String

	#if os(iOS)
		let watchSync: PhoneWatchSyncBridge

		@Binding var syncStatus: SyncMode

	#else
		@Binding var expanded: WindowMode
	#endif

	@State private var showCalendarImportSheet = false
	@State private var showEditTimetableSheet = false
	@State private var widgetReloadState: Bool = false

	@State private var showEditReceivedTimetablesSheet = false

	@Namespace private var ns

	#if os(iOS)
		init(watchSync: PhoneWatchSyncBridge, syncStatus: Binding<SyncMode>) {
			_username = State(initialValue: Defaults[.userDisplayName])

			self.watchSync = watchSync
			_syncStatus = syncStatus
		}
	#else
		init(expanded: Binding<WindowMode>) {
			_expanded = expanded
			_username = State(initialValue: Defaults[.userDisplayName])
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
					.onAppear {
						expanded = .settings
					}
					.onDisappear {
						expanded = .none
					}
				#endif
			}
			.scrollEdgeEffectStyle(.soft, for: .top)
			.scrollContentBackground(.hidden)
			.toolbar {
				#if os(iOS)
					ToolbarItem(placement: .title) {
						Text("Settings")
							.monospaced()
					}
				#endif // os(iOS)
			}
		}
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

		#if os(iOS)
			Section("Sync to Watch") {
				SyncButton(
					syncStatus: syncStatus,
					action: {
						Task {
							await syncToWatchAsync(
								subjects: subjects,
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
				SubjectEditorSheet(
					subjects: $subjects,
					initialRequest: nil
				)
				.presentationDetents([.fraction(0.85)])
				.presentationDragIndicator(.hidden)
				.interactiveDismissDisabled()
				#if os(iOS)
					.navigationTransition(.zoom(sourceID: "sheetMorph", in: ns))
				#else
					.frame(width: 600, height: 500)
				#endif
			}
		}

		#if !os(macOS)
			Section("Add Timetable to Wallet") {
				AddPassView()
			}
		#endif

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

		Section("Developer") {
			#if DEBUG
				Button("Test progress badge", systemImage: "progress.indicator") {
					addDebugStatusBadge(title: "Syncing account", view: .progressView(secondaryText: "Working"))
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
					addDebugStatusBadge(title: "Preparing Wallet pass", view: .progressViewAndGauge(currentStep: 2, totalSteps: 5, secondaryText: "Step 2 of 5"))
				}
			#endif // DEBUG

			Button {
				widgetReloadState = true
				WidgetCenter.shared.reloadAllTimelines()

				Task {
					try? await Task.sleep(nanoseconds: 5_000_000_000)
					await MainActor.run {
						withAnimation(.easeInOut) {
							widgetReloadState = false
						}
					}
				}
			} label: {
				ZStack {
					if widgetReloadState {
						Label("Done", systemImage: "checkmark")

							.transition(.blurReplace)
					} else {
						Label("Reload widgets now", systemImage: "widget.extralarge")
							.foregroundStyle(.accent)
							.transition(.blurReplace)
					}
				}
				.animation(.easeInOut, value: widgetReloadState)
			}
			.disabled(widgetReloadState)
		}
	}

	#if DEBUG
		private func addDebugStatusBadge(title: String, view: StatusBadgeView) {
			let id = UUID()
			statusBadgeManager.addBadge(id: id, title: title, priority: 3, view: view)

			Task {
				try? await Task.sleep(for: .seconds(2))
				statusBadgeManager.updateBadge(id: id, title: "Done", view: .success)
			}
		}
	#endif
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
