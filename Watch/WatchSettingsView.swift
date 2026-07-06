import Defaults
import SwiftUI
import WidgetKit

struct WatchSettingsView: View {
	@Default(.accountProfile) private var profile
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List {
			Section("Account") {
				if let profile {
					LabeledContent("Name", value: profile.displayName)
					if let email = profile.email {
						LabeledContent("Email", value: email)
					}
				}
				Button("Sign Out", role: .destructive) {
					Task { await SessionStore.shared.signOut() }
				}
			}

			#if DEBUG
				Section("Developer") {
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

	private func reloadWidgets() {
		WidgetCenter.shared.reloadAllTimelines()
		badges.addBadge(id: UUID(), title: "Widgets Reloaded", priority: 3, view: .success)
	}
}
