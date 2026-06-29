//
//   AccountAndSyncSettingsView.swift
//   Main
//
//   Created by Codex on 29/6/2026.
//

import Defaults
import SwiftUI

struct AccountAndSyncSettingsView: View {
	@State private var settings = Defaults[.accountSettings]
	@State private var settingsSync = AccountSettingsSyncService.shared

	var body: some View {
		Form {
			Section("Notifications") {
				Toggle("Allow Notifications", isOn: $settings.notificationsEnabled)
			}

			Section("Live Activities") {
				Toggle("Live Activities", isOn: $settings.liveActivitiesEnabled)
				Toggle("Show Breaks", isOn: $settings.showBreaksInLiveActivity)
				Toggle("Show Next Subject", isOn: $settings.showNextSubjectInLiveActivity)

				LabeledContent("Start Time") {
					TimeOfDayPicker(time: $settings.liveActivityStartTime)
				}
				LabeledContent("End Time") {
					TimeOfDayPicker(time: $settings.liveActivityEndTime)
				}

				ForEach(SchoolWeekday.allCases, id: \.self) { weekday in
					Button {
						toggle(weekday)
					} label: {
						HStack {
							Text(weekday.title)
							Spacer()
							if settings.liveActivityWeekdays.contains(weekday) {
								Image(systemName: "checkmark")
							}
						}
					}
					.buttonStyle(.plain)
				}
			}

			Section("System Integrations") {
				Toggle("Received Timetables in Widgets", isOn: $settings.widgetShowsReceivedTimetables)
				Toggle("Spotlight Indexing", isOn: $settings.spotlightIndexingEnabled)
				Toggle("Siri Access", isOn: $settings.siriAccessEnabled)
			}
		}
		.navigationTitle("Account and Sync")
		.onChange(of: settings) { oldValue, newValue in
			guard oldValue != newValue else { return }
			Task {
				do {
					try await settingsSync.updateSettings(newValue)
				} catch {
					settings = Defaults[.accountSettings]
				}
			}
		}
	}

	private func toggle(_ weekday: SchoolWeekday) {
		if settings.liveActivityWeekdays.contains(weekday) {
			guard settings.liveActivityWeekdays.count > 1 else { return }
			settings.liveActivityWeekdays.remove(weekday)
		} else {
			settings.liveActivityWeekdays.insert(weekday)
		}
	}
}

private struct TimeOfDayPicker: View {
	@Binding var time: TimeOfDay

	var body: some View {
		HStack(spacing: 4) {
			Picker("Hour", selection: $time.hour) {
				ForEach(0 ..< 24, id: \.self) { hour in
					Text(hour.formatted(.number.precision(.integerLength(2)))).tag(hour)
				}
			}
			.labelsHidden()
			.frame(width: 55)

			Text(":")

			Picker("Minute", selection: $time.minute) {
				ForEach(0 ..< 60, id: \.self) { minute in
					Text(minute.formatted(.number.precision(.integerLength(2)))).tag(minute)
				}
			}
			.labelsHidden()
			.frame(width: 55)
		}
	}
}
