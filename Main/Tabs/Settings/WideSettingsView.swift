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
	@Default(.ownerTimetableShareAlias) private var ownerTimetableShareAlias
	@State private var showsShareAliasEditor = false

	var body: some View {
		@Bindable var router = router

		Form {
			Section("Account") {
				routeButton("Account", systemImage: "person.crop.circle", route: .settings(.account))
			}

			Section("Preferences") {
				routeButton("Updates & Notifications", systemImage: "switch.2", route: .settings(.updatesAndNotifications))
				routeButton("Subscribed Event Tags", systemImage: "tag", route: .settings(.tagSubscriptions))
				Toggle("Highlight Current Day in timetables", systemImage: "inset.filled.lefthalf.righthalf.rectangle", isOn: highlightsCurrentDay)
				Toggle("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right", isOn: $hapticsEnabled)
				Toggle(
					"Restore Navigation",
					systemImage: "arrow.counterclockwise.circle",
					isOn: $router.persistsNavigationState
				)
			}

			Section("Timetable Management") {
				routeButton("Created Timetables", systemImage: "person.2.crop.square.stack", route: .settings(.createdTimetables))
				routeButton("Received Timetables", systemImage: "square.and.arrow.down", route: .settings(.receivedTimetables))
				if let ownerShareURL {
					ShareLink(item: ownerShareURL) {
						Label("Share My Timetable", systemImage: "square.and.arrow.up")
					}
				}
				Button("Customize Share Link", systemImage: "link.badge.plus") {
					showsShareAliasEditor = true
				}
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
		.popover(isPresented: $showsShareAliasEditor) {
			TimetableShareAliasSheet(close: { showsShareAliasEditor = false })
				.frame(iOS: .init(), macOS: .init(width: 620, height: 660))
				.presentationCompactAdaptation(.sheet)
		}
	}

	private var ownerShareURL: URL? {
		guard let ownerID = UUID(uuidString: Defaults[.ownerTimetableID]) else {
			return nil
		}
		return TimetableShareURL.ownerURL(id: ownerID, alias: ownerTimetableShareAlias)
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
		let isSelected = router.inspectorRoute == route

		return Button {
			if isSelected {
				router.inspectorRoute = nil
			} else {
				router.navigate(to: route)
			}
		} label: {
			HStack {
				Label {
					Text(title)
						.foregroundStyle(isSelected ? .white : .primary)
				} icon: {
					Image(systemName: systemImage)
						.foregroundStyle(isSelected ? .white : .accent)
				}
				Spacer()
				Image(systemName: "chevron.right")
					.foregroundStyle(isSelected ? .white : .secondary)
			}
			.contentShape(Rectangle())
		}
		.listRowBackground(isSelected ? Color.accentColor : nil)
		.buttonStyle(.plain)
		.tint(.accentColor)
	}
}
