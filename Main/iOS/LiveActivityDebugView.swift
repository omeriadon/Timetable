//
//  LiveActivityDebugView.swift
//  Timetable
//
//  Created by Adon Omeri on 5/7/2026.
//

import ActivityKit
import SwiftUI

@MainActor
struct LiveActivityDebugView: View {
	@State private var activity: Activity<SchoolDayActivityAttributes>?
	@State private var status = "Idle"

	var body: some View {
		Form {
			Text(status)

			Button("Start Before School Activity") {
				Task {
					await startActivity()
				}
			}

			Button("Update to Lesson") {
				Task {
					await updateActivity(
						phase: .lesson,
						title: "Some really long name here",
						symbol: "flask.fill",
						nextText: "very long name here too",
						duration: 45 * 60
					)
				}
			}

			Button("Update to Recess") {
				Task {
					await updateActivity(
						phase: .recess,
						title: "Recess",
						symbol: "cup.and.saucer.fill",
						nextText: "English",
						duration: 20 * 60
					)
				}
			}

			Button("End Activity") {
				Task {
					await endActivity()
				}
			}
		}
		.padding()
	}

	private func startActivity() async {
		guard ActivityAuthorizationInfo().areActivitiesEnabled else {
			status = "Live Activities disabled in Settings"
			return
		}

		let attributes = SchoolDayActivityAttributes(
			activityKey: UUID().uuidString,
			schoolDate: ISO8601DateFormatter().string(from: Date())
		)

		let state = SchoolDayActivityAttributes.ContentState(
			phase: .recess,
			title: "Before School",
			symbol: "atom",
			color: RGBAColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0),
			nextText: "Methods",
			startDate: Date(),
			endDate: Date().addingTimeInterval(15 * 60)
		)

		do {
			activity = try Activity.request(
				attributes: attributes,
				content: .init(state: state, staleDate: nil),
				pushType: .token
			)

			status = "Started \(activity?.id ?? "")"
		} catch {
			status = "Failed: \(error.localizedDescription)"
		}
	}

	private func updateActivity(
		phase: SchoolDayActivityAttributes.Phase,
		title: String,
		symbol: String,
		nextText: String?,
		duration: TimeInterval
	) async {
		let state = SchoolDayActivityAttributes.ContentState(
			phase: phase,
			title: title,
			symbol: symbol,
			color: RGBAColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0),
			nextText: nextText,
			startDate: Date(),
			endDate: Date().addingTimeInterval(duration)
		)

		let content = ActivityContent(
			state: state,
			staleDate: Date().addingTimeInterval(duration + 60)
		)

		for activity in Activity<SchoolDayActivityAttributes>.activities {
			await activity.update(content)
		}

		status = "Updated to \(title)"
	}

	private func endActivity() async {
		let state = SchoolDayActivityAttributes.ContentState(
			phase: .finished,
			title: "Finished",
			symbol: "checkmark.circle.fill",
			color: RGBAColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0),
			nextText: nil,
			startDate: nil,
			endDate: nil
		)

		let content = ActivityContent(
			state: state,
			staleDate: nil
		)

		for activity in Activity<SchoolDayActivityAttributes>.activities {
			await activity.end(content, dismissalPolicy: .immediate)
		}

		status = "Ended"
	}
}
