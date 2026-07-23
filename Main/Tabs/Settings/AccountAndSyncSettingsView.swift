//
//   AccountAndSyncSettingsView.swift
//   Main
//
//   Created by Adon Omeri on 29/6/2026.
//

import Defaults
import SwiftUI

struct AccountAndSyncSettingsView: View {
	@State private var settings = Defaults[.accountSettings]
	@State private var networkManager = NetworkManager.shared
	@State private var settingsSync = AccountSettingsSyncService.shared

	@State private var notificationRegistration = NotificationRegistrationService.shared

	@State private var testResult: String?
	@Environment(\.statusBadgeManager) private var badges
	@State private var committedSettings = Defaults[.accountSettings]
	@State private var saveGeneration = 0

	var body: some View {
		Form {
			#if os(iOS)
				Toggle(isOn: preferenceBinding(\.liveActivitiesEnabled)) {
					Text("Live Activities")
					Text("Show live countdowns and details for your subjects and breaks throughout the school day, including on your Watch.")
				}
			#endif

			Section {
				Toggle(isOn: preferenceBinding(\.notificationsEnabled)) {
					Text("Allow Class Notifications")
					Text("Send notifications for each class throughout the day.")
				}

				NotificationLeadTimesEditor(selection: leadTimesBinding)
					.disabled(!settings.notificationsEnabled)
					.opacity(settings.notificationsEnabled ? 1 : 0.3)

				#if os(iOS)
					Button {
						Task {
							do {
								let count = try await notificationRegistration.sendTestNotification()
								testResult = count == 1 ? "Sent to 1 device." : "Sent to \(count) devices."
							} catch {
								testResult = error.localizedDescription
							}
						}
					} label: {
						VStack(alignment: .leading) {
							Label("Send Test Notification", systemImage: "bell.badge")
							switch notificationRegistration.registrationState {
								case let .failed(message):
									Text(message).foregroundStyle(.red.secondary)
								case .registering:
									Text("Registering this device…").foregroundStyle(.secondary)
								case .idle, .tokenReceived:
									Text("Sign in and wait for device registration to finish.").foregroundStyle(.secondary)
								case .registered:
									EmptyView()
							}
						}
						.font(.callout)
					}
					.disabled(!settings.notificationsEnabled || notificationRegistration.registrationState != .registered)
					.onChange(of: testResult) {
						if let testResult {
							if testResult == "Sent to 0 devices." {
								badges.addBadge(id: UUID(), title: testResult, priority: 4, view: .error)
							} else if testResult.contains("devices") || testResult == "Sent to 1 device." {
								badges.addBadge(id: UUID(), title: testResult, priority: 4, view: .success)
							} else {
								badges.addBadge(id: UUID(), title: testResult, priority: 4, view: .error)
							}
						}
					}
				#endif // os(iOS)
			}

			Section {
				Toggle(isOn: preferenceBinding(\.broadcastNotificationsEnabled)) {
					Text("Special Event Notifications")
					Text("Special Event Notifications include announcements and limited-time events, such as special school events.")
				}
			}
		}
		.disabled(!networkManager.isOnline)
		.overlay {
			if !networkManager.isOnline {
				ContentUnavailableView("Offline", systemImage: "wifi.slash", description: Text("Account preferences are unavailable until a connection is restored."))
			}
		}
		.animation(.easeInOut, value: notificationRegistration.registrationState)
		#if os(macOS)
			.formStyle(.grouped)
			.scrollContentBackground(.hidden)
			.frame(maxWidth: 560)
		#endif
			.appNavigationTitle("Live Updates")
	}

	private func preferenceBinding(_ keyPath: WritableKeyPath<AccountSettings, Bool>) -> Binding<Bool> {
		Binding(
			get: { settings[keyPath: keyPath] },
			set: { value in
				saveGeneration += 1
				let generation = saveGeneration
				let previous = committedSettings
				settings[keyPath: keyPath] = value
				let proposed = settings
				Task { await save(proposed, previous: previous, generation: generation) }
			}
		)
	}

	private var leadTimesBinding: Binding<Set<NotificationLeadTime>> {
		Binding(
			get: { settings.notificationLeadTimes },
			set: { value in
				saveGeneration += 1
				let generation = saveGeneration
				let previous = committedSettings
				settings.notificationLeadTimes = value
				let proposed = settings
				Task { await save(proposed, previous: previous, generation: generation) }
			}
		)
	}

	private func save(_ proposed: AccountSettings, previous: AccountSettings, generation: Int) async {
		do {
			try await settingsSync.updateSettings(proposed)
			guard generation == saveGeneration else { return }
			committedSettings = proposed
			badges.addBadge(id: UUID(), title: "Preferences saved", priority: 3, view: .success)
		} catch {
			guard generation == saveGeneration else { return }
			settings = previous
			badges.addBadge(id: UUID(), title: "Unable to save preferences", secondaryText: error.localizedDescription, priority: 4, view: .error)
		}
	}
}

struct NotificationLeadTimesEditor: View {
	@Binding var selection: Set<NotificationLeadTime>

	var body: some View {
		#if os(macOS)
			VStack(alignment: .leading) {
				Text("Send Notifications Early By")
				ForEach(NotificationLeadTime.allCases, id: \.self) { leadTime in
					Toggle(leadTime.label, isOn: containsBinding(leadTime))
						.toggleStyle(.checkbox)
				}
			}
		#else
			NavigationLink {
				NotificationLeadTimesSelectionView(selection: $selection)
			} label: {
				LabeledContent("Send Notifications Early By", value: summary)
			}
		#endif
	}

	private var summary: String {
		selection.isEmpty ? "None" : selection.sorted { $0.minutes < $1.minutes }.map(\.label).joined(separator: ", ")
	}

	private func containsBinding(_ leadTime: NotificationLeadTime) -> Binding<Bool> {
		Binding(
			get: { selection.contains(leadTime) },
			set: { isSelected in
				if isSelected {
					selection.insert(leadTime)
				} else {
					selection.remove(leadTime)
				}
			}
		)
	}
}

#if os(iOS)
	private struct NotificationLeadTimesSelectionView: View {
		@Binding var selection: Set<NotificationLeadTime>

		var body: some View {
			List(NotificationLeadTime.allCases, id: \.self) { leadTime in
				Button {
					if selection.contains(leadTime) {
						selection.remove(leadTime)
					} else {
						selection.insert(leadTime)
					}
				} label: {
					HStack {
						Text(leadTime.label)
						Spacer()
						if selection.contains(leadTime) {
							Image(systemName: "checkmark")
						}
					}
				}
				.buttonStyle(.plain)
			}
			.appNavigationTitle("Notify Me")
		}
	}
#endif

private extension NotificationLeadTime {
	var label: String {
		"\(minutes) \(minutes == 1 ? "minute" : "minutes") early"
	}
}
