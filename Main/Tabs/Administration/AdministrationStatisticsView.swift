//
//  AdministrationStatisticsView.swift
//  Main
//

import Defaults
import SwiftUI

struct AdministrationStatisticsView: View {
	@State private var service = LocationStatusStatisticsService.shared
	@State private var statistics: AdministrationStatisticsResponse?
	@Default(.friends) private var friends
	@Default(.calendarEvents) private var calendarEvents
	@Default(.eventTagSubscriptionIDs) private var subscribedTagIDs
	@Default(.incomingFriendRequests) private var incomingFriendRequests
	@Environment(\.statusBadgeManager) private var statusBadges

	var body: some View {
		List {
			Section("Users") {
				LabeledContent("Total users") {
					Text(statistics?.totalUsers.formatted() ?? "No data")
				}
				LabeledContent("Users with a timetable") {
					Text(statistics?.usersWithOwnerTimetable.formatted() ?? "No data")
				}
			}

			Section("Grades") {
				LabeledContent("Assessments") {
					Text(statistics?.totalAssessments.formatted() ?? "No data")
				}
				LabeledContent("Average assessments per user") {
					Text(formattedAverage(statistics?.averageAssessmentsPerUser))
				}
				LabeledContent("Average assessments for users with multiple assessments") {
					Text(formattedAverage(statistics?.averageAssessmentsPerUserWithMultipleAssessments))
				}
			}

			Section("Devices") {
				LabeledContent("All devices") {
					Text(statistics?.totalDevices.formatted() ?? "No data")
				}
				LabeledContent("Active devices in the last 30 days") {
					Text(statistics?.activeDevicesLast30Days.formatted() ?? "No data")
				}
				LabeledContent("iPhone devices") {
					Text(statistics?.iPhoneDevices.formatted() ?? "No data")
				}
				LabeledContent("iPad devices") {
					Text(statistics?.iPadDevices.formatted() ?? "No data")
				}
				LabeledContent("Mac devices") {
					Text(statistics?.macDevices.formatted() ?? "No data")
				}
				LabeledContent("Apple Watch devices") {
					Text(statistics?.watchDevices.formatted() ?? "No data")
				}
				LabeledContent("Legacy devices") {
					Text(statistics?.legacyDevices.formatted() ?? "No data")
				}
			}

			Section("Community") {
				LabeledContent("Friends in account", value: friends.count.formatted())
				LabeledContent("Pending friend requests", value: incomingFriendRequests.count.formatted())
				LabeledContent("Accepted friendships") {
					Text(statistics?.acceptedFriendships.formatted() ?? "No data")
				}
				LabeledContent("Average friends per user") {
					Text(formattedAverage(statistics?.averageFriendsPerUser))
				}
				LabeledContent("Average friends for users with friends") {
					Text(formattedAverage(statistics?.averageFriendsPerUserWithFriends))
				}
				LabeledContent("Subscribed event tags", value: subscribedTagIDs.count.formatted())
				LabeledContent("All active tag subscriptions") {
					Text(statistics?.activeEventTagSubscriptions.formatted() ?? "No data")
				}
			}

			Section("Calendar") {
				LabeledContent("Visible events", value: calendarEvents.allEvents.count.formatted())
				LabeledContent("All calendar events") {
					Text(statistics?.totalCalendarEvents.formatted() ?? "No data")
				}
				LabeledContent("Global events") {
					Text(statistics?.globalCalendarEvents.formatted() ?? "No data")
				}
				LabeledContent("Personal events") {
					Text(statistics?.personalCalendarEvents.formatted() ?? "No data")
				}
			}

			Section("Status") {
				LabeledContent("Average arrival") {
					Text(formattedAverageArrival)
				}
			}
		}
		.scrollEdgeEffect()
		.appNavigationTitle("Statistics", accent: true)
		.refreshable {
			await load()
		}
		.task {
			await load()
		}
	}

	private var formattedAverageArrival: String {
		guard let seconds = statistics?.averageArrivalSecondsSinceMidnight else {
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
		do {
			statistics = try await service.administrationStatistics()
		} catch {
			statusBadges.present(error: error, title: "Unable to load statistics")
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
