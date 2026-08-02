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
					.opacity(settings.notificationsEnabled ? 1 : 0.5)

				BreakToPeriodNotificationLeadTimesEditor(selection: breakToPeriodLeadTimesBinding)
					.disabled(!settings.notificationsEnabled)
					.opacity(settings.notificationsEnabled ? 1 : 0.5)
			}

			Section {
				Toggle(isOn: preferenceBinding(\.broadcastNotificationsEnabled)) {
					Text("Special Event Notifications")
					Text("Special Event Notifications include announcements and limited-time events, such as special school events.")
				}
			}

			Section("Event Notifications") {
				EventNotificationSchedulesEditor(selection: eventNotificationSchedulesBinding)
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
			.appNavigationTitle("Updates", accent: true)
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

	private var breakToPeriodLeadTimesBinding: Binding<Set<NotificationLeadTime>> {
		Binding(
			get: { settings.breakToPeriodNotificationLeadTimes },
			set: { value in
				saveGeneration += 1
				let generation = saveGeneration
				let previous = committedSettings
				settings.breakToPeriodNotificationLeadTimes = value
				let proposed = settings
				Task { await save(proposed, previous: previous, generation: generation) }
			}
		)
	}

	private var eventNotificationSchedulesBinding: Binding<Set<EventNotificationSchedule>> {
		Binding(
			get: { settings.eventNotificationSchedules },
			set: { value in
				saveGeneration += 1
				let generation = saveGeneration
				let previous = committedSettings
				settings.eventNotificationSchedules = value
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
		} catch {
			guard generation == saveGeneration else { return }
			settings = previous
			badges.addBadge(id: UUID(), title: "Unable to save preferences", secondaryText: error.localizedDescription, priority: 4, view: .error)
		}
	}
}

struct BreakToPeriodNotificationLeadTimesEditor: View {
	@Binding var selection: Set<NotificationLeadTime>

	var body: some View {
		#if os(macOS)
			VStack(alignment: .leading) {
				Text("Before Class or From a Break")
				Text("Applies before first period and after recess or lunch.")
					.font(.footnote)
					.foregroundStyle(.secondary)
				ForEach(NotificationLeadTime.allCases, id: \.self) { leadTime in
					Toggle(leadTime.label, isOn: containsBinding(leadTime))
						.toggleStyle(.checkbox)
				}
			}
		#else
			NavigationLink {
				NotificationLeadTimesSelectionView(
					title: "Notify Me",
					description: "Applies before first period and after recess or lunch.",
					selection: $selection
				)
			} label: {
				LabeledContent("Before Class or From a Break") {
					VStack(alignment: .leading) {
						ForEach(summary, id: \.self) { i in
							Text(i)
						}
					}
					.foregroundStyle(.secondary)
				}
			}
		#endif
	}

	private var summary: [String] {
		selection.isEmpty ? [] : selection.sorted { $0.minutes < $1.minutes }.map(\.label)
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

struct EventNotificationSchedulesEditor: View {
	@Binding var selection: Set<EventNotificationSchedule>
	@State private var isAdding = false
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	var body: some View {
		ForEach(selection.sorted { lhs, rhs in
			if lhs.dayOffset != rhs.dayOffset {
				return lhs.dayOffset < rhs.dayOffset
			}
			if lhs.hour != rhs.hour {
				return lhs.hour < rhs.hour
			}
			return lhs.minute < rhs.minute
		}, id: \.self) { schedule in
			HStack {
				Text(schedule.timeLabel)
				Text(schedule.offsetLabel)
					.textCase(.lowercase)
					.foregroundStyle(.secondary)
				Spacer()
				Button("Remove", systemImage: "minus.circle", role: .destructive) {
					withAnimation(reduceMotion ? nil : .snappy) {
						_ = selection.remove(schedule)
					}
				}
				.foregroundStyle(.red)
				.labelStyle(.iconOnly)
			}
			.transition(.move(edge: .top).combined(with: .opacity))
		}
		Button("Add Event Notification", systemImage: "plus") { isAdding = true }
			.sheet(isPresented: $isAdding) { EventNotificationScheduleSheet(selection: $selection) }
			.animation(reduceMotion ? nil : .snappy, value: selection)
	}
}

private struct EventNotificationScheduleSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Binding var selection: Set<EventNotificationSchedule>
	@State private var timeMinutes = 8 * 60
	@State private var dayOffset = 0
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	var body: some View {
		NavigationStack {
			Form {
				Picker("Send notification", selection: $dayOffset) {
					Text("On the day")
						.foregroundStyle(.accent)
						.tag(0)
					Text("1 day before")
						.foregroundStyle(.accent)
						.tag(1)
					Text("2 days before")
						.foregroundStyle(.accent)
						.tag(2)
					Text("3 days before")
						.foregroundStyle(.accent)
						.tag(3)
					Text("1 week before")
						.foregroundStyle(.accent)
						.tag(7)
				}

				Picker("Time", selection: $timeMinutes) {
					ForEach(Array(stride(from: 5 * 60, through: 22 * 60, by: 15)), id: \.self) { minutes in
						Text(timeLabel(minutes)).tag(minutes)
					}
				}
				.pickerStyle(.wheel)
			}
			.interactiveDismissDisabled()
			.presentationDetents([.medium])
			.appNavigationTitle("Event Notification", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) { Button(role: .cancel) { dismiss() } }
				ToolbarItem(placement: .confirmationAction) {
					Button("Add", systemImage: "plus", role: .confirm) {
						withAnimation(reduceMotion ? nil : .snappy) {
							_ = selection.insert(
								EventNotificationSchedule(
									hour: timeMinutes / 60,
									minute: timeMinutes % 60,
									dayOffset: dayOffset
								)
							)
						}
						dismiss()
					}
					.buttonStyle(.glassProminent)
				}
			}
		}
	}

	private func timeLabel(_ minutes: Int) -> String {
		DateFormatter.localizedString(from: Calendar.current.date(from: DateComponents(hour: minutes / 60, minute: minutes % 60)) ?? .now, dateStyle: .none, timeStyle: .short)
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
				LabeledContent("Send Notifications Early By") {
					VStack(alignment: .leading) {
						ForEach(summary, id: \.self) { i in
							Text(i)
						}
					}
					.foregroundStyle(.secondary)
				}
			}
		#endif
	}

	private var summary: [String] {
		selection.isEmpty
			? ["None"]
			: selection
			.sorted { $0.minutes < $1.minutes }
			.map(\.label)
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
	struct NotificationLeadTimesSelectionView: View {
		let title: String
		let description: String?
		@Binding var selection: Set<NotificationLeadTime>

		init(title: String = "Notify Me", description: String? = nil, selection: Binding<Set<NotificationLeadTime>>) {
			self.title = title
			self.description = description
			_selection = selection
		}

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
								.foregroundStyle(.accent)
						}
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.contentShape(Rectangle())
				}
				.buttonSizing(.flexible)
				.buttonStyle(.plain)
			}
			.safeAreaBar(edge: .top, alignment: .center, spacing: 5) {
				if let description {
					Text(description)
				}
			}
			.appNavigationTitle(title, accent: true)
		}
	}
#endif // os(iOS)

private extension NotificationLeadTime {
	var label: String {
		"\(minutes) \(minutes == 1 ? "minute" : "minutes") early"
	}
}
