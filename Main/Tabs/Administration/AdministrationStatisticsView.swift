//
//  AdministrationStatisticsView.swift
//  Main
//

import SwiftUI

struct AdministrationStatisticsView: View {
	@State private var service = LocationStatusStatisticsService.shared
	@State private var statistics: AdministrationStatisticsResponse?
	@Environment(\.statusBadgeManager) private var statusBadges

	var body: some View {
		List {
			Section("Users") {
				LabeledContent("Total users") {
					Text(statistics?.totalUsers.formatted() ?? "No data")
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
