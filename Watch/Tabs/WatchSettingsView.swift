import Defaults
import SwiftUI
import WidgetKit

struct WatchSettingsView: View {
	@Default(.accountProfile) private var profile
	@Default(.debugOffset) private var debugOffset
	@Default(.accountSettings) private var accountSettings
	@Environment(\.statusBadgeManager) private var badges

	@State private var bootstrapService = WatchAccountBootstrapService.shared
	@State private var signOutConfirm = false

	var body: some View {
		NavigationStack {
			List {
				Section("Account") {
					if let profile {
						LabeledContent("Name", value: profile.displayName)
						LabeledContent("Email", value: profile.email)
							.lineLimit(2)
					}
					Button("Sign Out", systemImage: "door.left.hand.open", role: .destructive) {
						signOutConfirm = true
					}
					.foregroundStyle(.red)
					.confirmationDialog(Text("Sign Out?"), isPresented: $signOutConfirm, actions: {
						Button(role: .cancel) {}
						Button(role: .destructive) {
							Task { await SessionStore.shared.signOut() }
						} label: {
							Label("Sign out", systemImage: "door.left.hand.open")
								.foregroundStyle(.red)
						}
					})
				}

				Section("Server") {
					Button {
						Task(priority: .userInitiated) {
							await syncFromServer()
						}
					} label: {
						if bootstrapService.isSyncing {
							Label("Syncing", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
						} else {
							Label("Sync from Server", systemImage: "arrow.down.circle")
						}
					}
					.disabled(bootstrapService.isSyncing)
				}

				Section("Appearance") {
					Toggle("Bleed", systemImage: "drop.degreesign", isOn: bleedBinding)
				}

				#if DEBUG
					Section("Developer") {
						LabeledContent("Debug Offset") {
							TextField("Seconds", value: $debugOffset, format: .number)
								.multilineTextAlignment(.trailing)
						}
						Button("Test Progress", systemImage: "progress.indicator") {
							testBadge(title: "Syncing account", secondaryText: "Working", view: .progressView)
						}
						Button("Test Success", systemImage: "checkmark.circle") {
							testBadge(title: "Saving timetable", view: .success)
						}
						Button("Test Info", systemImage: "info.circle") {
							testBadge(title: "Info here", view: .info)
						}
						Button("Test Error", systemImage: "xmark.circle") {
							testBadge(title: "Contacting server", view: .error)
						}
						Button("Test Warning", systemImage: "exclamationmark.triangle") {
							testBadge(title: "Checking timetable", view: .warning)
						}
						Button("Test Progress and Gauge", systemImage: "arrow.trianglehead.2.clockwise.rotate.90") {
							Task { await testProgressGauge() }
						}
						Button("Reload Widgets", systemImage: "arrow.clockwise", action: reloadWidgets)
					}
				#endif
			}
			.scrollEdgeEffectStyle(.soft, for: .top)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Text("Timetable")
						.bold()
						.font(.title3)
				}
			}
		}
	}

	#if DEBUG
		private func testBadge(title: String, secondaryText: String? = nil, view: StatusBadgeView) {
			let id = UUID()
			badges.addBadge(id: id, title: title, secondaryText: secondaryText, priority: 3, view: view)

			guard view == .progressView else { return }
			Task {
				try? await Task.sleep(for: .seconds(2))
				badges.updateBadge(id: id, title: "Done", view: .success)
			}
		}

		private func testProgressGauge() async {
			let id = UUID()
			badges.addBadge(id: id, title: "Preparing", secondaryText: "Step 1 of 3", priority: 3, view: .progressViewAndGauge(currentStep: 1, totalSteps: 3))
			try? await Task.sleep(for: .seconds(1))
			badges.updateBadge(id: id, title: "Preparing", secondaryText: "Step 2 of 3", view: .progressViewAndGauge(currentStep: 2, totalSteps: 3))
			try? await Task.sleep(for: .seconds(1))
			badges.updateBadge(id: id, title: "Prepared", view: .success)
		}
	#endif

	private func syncFromServer() async {
		guard !bootstrapService.isSyncing else { return }

		do {
			try await bootstrapService.bootstrap()
			WidgetCenter.shared.reloadAllTimelines()
			badges.addBadge(id: UUID(), title: "Synced from Server", priority: 3, view: .success)
		} catch {
			badges.present(error: error, title: "Unable to Sync")
		}
	}

	private func reloadWidgets() {
		WidgetCenter.shared.reloadAllTimelines()
		badges.addBadge(id: UUID(), title: "Widgets Reloaded", priority: 3, view: .success)
	}

	private var bleedBinding: Binding<Bool> {
		Binding(
			get: { accountSettings.watchBleedEnabled },
			set: { enabled in
				let previous = accountSettings
				var proposed = accountSettings
				proposed.watchBleedEnabled = enabled
				accountSettings = proposed

				Task {
					do {
						let updated: AccountSettings = try await NetworkManager.shared.send(
							.v1SettingsUpdate,
							body: proposed
						)
						accountSettings = updated
					} catch {
						accountSettings = previous
						badges.present(error: error, title: "Unable to Save Bleed")
					}
				}
			}
		)
	}
}

private extension Endpoint {
	static let v1SettingsUpdate = Endpoint("/v1/settings", method: .put)
}
