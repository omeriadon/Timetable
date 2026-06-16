//
//  TimeLeftView.swift
//  Widget Extension
//
//  Created by Adon Omeri on 13/5/2026.
//

import SwiftUI
import WidgetKit

struct TimeLeftView: View {
	let entry: TimetableEntry

	let state: SchoolState

	// MARK: - body

	var body: some View {
		Group {
			switch state {
				case let .beforeSchool(next):
					VStack(alignment: Device.isWatchOS ? .leading : .center) {
						Spacer()
						Spacer()

						Text("Before School")
							.font(Device.isWatchOS ? .caption : .headline)
							.foregroundColor(.secondary)

						Spacer()

						Label("First Period: \(next.id)", systemImage: next.symbol)
							.font(Device.isWatchOS ? .title3 : .title)

						Spacer()
						Spacer()
					}

				case let .inClass(current, nextText, info):
					createProgressView(
						title: current?.id ?? "Free Period",
						symbol: current?.symbol ?? "studentdesk",
						nextText: nextText,
						start: info.start,
						end: info.end
					)

				case let .inBreak(title, nextText, info):
					createProgressView(
						title: title,
						symbol: title == "Lunch" ? "takeoutbag.and.cup.and.straw.fill" : "cup.and.saucer.fill",
						nextText: nextText,
						start: info.start,
						end: info.end
					)

				case .outsideSchool:
					VStack(alignment: Device.isWatchOS ? .leading : .center) {
						Spacer()
						Spacer()

						Label("School's Out", systemImage: "house.fill")
							.font(Device.isWatchOS ? .title3 : .title)
							.foregroundColor(.indigo)

						Spacer()

						Text("No more classes")
							.font(Device.isWatchOS ? .caption : .headline)
							.foregroundColor(.secondary)

						Spacer()
						Spacer()
					}
			}
		}
		.monospaced()
	}

	// MARK: - createProgressView

	private func createProgressView(
		title: String,
		symbol: String,
		nextText: String,
		start _: Date,
		end: Date
	) -> some View {
		VStack(alignment: .leading) {
			Label(title, systemImage: symbol)
				.font(Device.isWatchOS ? .headline : .title)
				.lineLimit(1)

			Spacer(minLength: 1)

			Text(end, style: .timer)
				.font(Device.isWatchOS ? .body : .largeTitle.scaled(by: 1.3))
				.contentTransition(.numericText(countsDown: true))

			Spacer(minLength: 1)

			Text(nextText)
				.font(Device.isWatchOS ? .body.scaled(by: 0.9) : .title3)
				.foregroundStyle(.secondary)
				.lineLimit(1)
		}
		.padding([.vertical, .leading])
	}
}

#Preview {
	TimeLeftView(
		entry: TimetableEntry(
			date: Date(),
			classes: defaultTimetable,
			relevance: TimelineEntryRelevance(score: 1, duration: 60 * 60)
		),
		state: .beforeSchool(next: defaultTimetable[0])
	)
}
