//
//  AdministrationStatisticsView.swift
//  Main
//

import Defaults
import Observation
import SwiftUI

struct AdministrationStatisticsView: View {
	@State private var model = AdministrationStatisticsModel()
	@Default(.friends) private var friends
	@Default(.calendarEvents) private var calendarEvents
	@Default(.eventTagSubscriptionIDs) private var subscribedTagIDs
	@Default(.incomingFriendRequests) private var incomingFriendRequests
	@Environment(\.statusBadgeManager) private var statusBadges

	var body: some View {
		List {
			Section("Users") {
				LabeledContent("Total users") {
					Text(model.statistics?.totalUsers.formatted() ?? "No data")
				}
				LabeledContent("Users with a timetable") {
					Text(model.statistics?.usersWithOwnerTimetable.formatted() ?? "No data")
				}
				LabeledContent("Users with assessments") {
					Text(model.statistics?.usersWithAssessments.formatted() ?? "No data")
				}
				LabeledContent("Users with location history") {
					Text(model.statistics?.usersWithLocationStatus.formatted() ?? "No data")
				}
			}
			.glurListRowBackground()

			Section("Grades") {
				LabeledContent("Assessments") {
					Text(model.statistics?.totalAssessments.formatted() ?? "No data")
				}
				LabeledContent("Average assessments per user") {
					Text(formattedAverage(model.statistics?.averageAssessmentsPerUser))
				}
				LabeledContent("Average assessments for users with assessments") {
					Text(formattedAverage(model.statistics?.averageAssessmentsPerUserWithMultipleAssessments))
				}
			}
			.glurListRowBackground()

			Section("Devices") {
				NavigationLink {
					AdministrationDeviceStatisticsView()
				} label: {
					Label("Devices", systemImage: "iphone.gen3")
				}
				LabeledContent("All devices") {
					Text(model.statistics?.totalDevices.formatted() ?? "No data")
				}
				LabeledContent("Active devices in the last 30 days") {
					Text(model.statistics?.activeDevicesLast30Days.formatted() ?? "No data")
				}
			}
			.glurListRowBackground()

			Section("Community") {
				LabeledContent("Friends in account", value: friends.count.formatted())
				LabeledContent("Pending friend requests", value: incomingFriendRequests.count.formatted())
				LabeledContent("Accepted friendships") {
					Text(model.statistics?.acceptedFriendships.formatted() ?? "No data")
				}
				LabeledContent("Average friends per user") {
					Text(formattedAverage(model.statistics?.averageFriendsPerUser))
				}
				LabeledContent("Average friends for users with friends") {
					Text(formattedAverage(model.statistics?.averageFriendsPerUserWithFriends))
				}
				LabeledContent("Subscribed event tags", value: subscribedTagIDs.count.formatted())
				LabeledContent("All active tag subscriptions") {
					Text(model.statistics?.activeEventTagSubscriptions.formatted() ?? "No data")
				}
			}
			.glurListRowBackground()

			Section("Calendar") {
				LabeledContent("Visible events", value: calendarEvents.allEvents.count.formatted())
				LabeledContent("All calendar events") {
					Text(model.statistics?.totalCalendarEvents.formatted() ?? "No data")
				}
				LabeledContent("Global events") {
					Text(model.statistics?.globalCalendarEvents.formatted() ?? "No data")
				}
				LabeledContent("Personal events") {
					Text(model.statistics?.personalCalendarEvents.formatted() ?? "No data")
				}
			}
			.glurListRowBackground()

			Section("Status") {
				LabeledContent("Average arrival") {
					Text(formattedAverageArrival)
				}
				LabeledContent("Recorded status updates") {
					Text(model.statistics?.totalLocationStatusUpdates.formatted() ?? "No data")
				}
			}
			.glurListRowBackground()
		}
		.scrollEdgeEffect()
		.appPaperBackground()
		.appNavigationTitle("Statistics", accent: true)
		.refreshable {
			await load()
		}
		.task {
			await load()
		}
	}

	private var formattedAverageArrival: String {
		guard let seconds = model.statistics?.averageArrivalSecondsSinceMidnight else {
			return "No data"
		}

		return LocationArrivalTimeFormatter.string(for: seconds)
	}

	private func formattedAverage(_ value: Double?) -> String {
		guard let value else {
			return "No data"
		}

		return value.formatted(.number.precision(.fractionLength(1)))
	}

	private func load() async {
		if let error = await model.load(), !Task.isCancelled, !error.isCancellation {
			statusBadges.present(error: error, title: "Unable to load statistics")
		}
	}
}

@MainActor
@Observable
final class AdministrationStatisticsModel {
	private(set) var statistics: AdministrationStatisticsResponse?

	func load() async -> Error? {
		guard !Task.isCancelled else {
			return nil
		}

		do {
			let response = try await LocationStatusStatisticsService.shared.administrationStatistics()
			guard !Task.isCancelled else {
				return nil
			}
			statistics = response
			return nil
		} catch is CancellationError {
			return nil
		} catch {
			return error
		}
	}
}

enum LocationArrivalTimeFormatter {
	static func string(for secondsSinceMidnight: Double) -> String {
		let calendar = SchoolCalendarProjection.perthCalendar
		let day = calendar.startOfDay(for: Date(timeIntervalSinceReferenceDate: 0))
		let date = day.addingTimeInterval(secondsSinceMidnight)
		return date.formatted(date: .omitted, time: .shortened)
	}
}
