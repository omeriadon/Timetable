import Defaults
import SwiftUI
import WidgetKit

struct WideSettingsView: View {
	@Environment(AppRouter.self) private var router
	@Environment(\.statusBadgeManager) private var badges
	@State private var settings = Defaults[.accountSettings]
	@State private var committedSettings = Defaults[.accountSettings]
	@State private var settingsSync = AccountSettingsSyncService.shared
	@State private var saveGeneration = 0
	@Default(.lastServerSync) private var lastServerSync
	@Default(.hapticsEnabled) private var hapticsEnabled

	var body: some View {
		Form {
			Section("Account") {
				routeButton("Account", systemImage: "person.crop.circle", route: .settings(.account))
				routeButton("Edit Profile", systemImage: "person.crop.circle.badge.checkmark", route: .settings(.profileAppearance))
			}

			Section("Preferences") {
				routeButton("Updates & Notifications", systemImage: "switch.2", route: .settings(.updatesAndNotifications))
				routeButton("Subscribed Event Tags", systemImage: "tag", route: .settings(.tagSubscriptions))
				Toggle("Highlight Current Day in timetables", systemImage: "inset.filled.lefthalf.righthalf.rectangle", isOn: highlightsCurrentDay)
				Toggle("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right", isOn: $hapticsEnabled)
				routeButton("Restore Navigation", systemImage: "arrow.counterclockwise.circle", route: .settings(.navigationPersistence))
			}

			Section("Support") {
				routeButton("Report Feedback or Bug", systemImage: "exclamationmark.bubble", route: .settings(.feedback))
				routeButton("About Timetable", systemImage: "info.circle", route: .settings(.about))
				Button("Reload Widgets", systemImage: "widget.large") {
					WidgetCenter.shared.reloadAllTimelines()
					badges.addBadge(id: UUID(), title: "Widgets reloaded", priority: 3, view: .success)
				}
				LabeledContent("Last Server Sync", value: lastServerSync?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
			}
		}
		.formStyle(.grouped)
		.scrollContentBackground(.hidden)
		.appNavigationTitle("Settings", style: .main, accent: true)
	}

	private var highlightsCurrentDay: Binding<Bool> {
		Binding(
			get: { settings.highlightsCurrentDay },
			set: { value in
				saveGeneration += 1
				let generation = saveGeneration
				let previous = committedSettings
				settings.highlightsCurrentDay = value
				let proposed = settings
				Task {
					do {
						try await settingsSync.updateSettings(proposed)
						guard generation == saveGeneration else {
							return
						}
						committedSettings = proposed
					} catch {
						guard generation == saveGeneration else {
							return
						}
						settings = previous
						badges.addBadge(id: UUID(), title: "Unable to save preferences", secondaryText: error.localizedDescription, priority: 4, view: .error)
					}
				}
			}
		)
	}

	private func routeButton(
		_ title: String,
		systemImage: String,
		route: AppRoute
	) -> some View {
		Button {
			router.navigate(to: route)
		} label: {
			Label(title, systemImage: systemImage)
		}
	}
}
