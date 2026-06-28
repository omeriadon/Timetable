//
//   FriendsTimeLeftWidget.swift
//   Widget
//
//   Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct FriendsTimeLeftWidget: Widget {
	let kind: String = "FriendsTimeLeft"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			let friendsSubjects = Defaults[.receivedTimetables]

			let friendScheduleItems: [ScheduleItem] = friendsSubjects.map {
				let friendSubjectLookup = TimetableLayout.subjectLookup(for: $0.subjects)
				let friendState = getSchoolState(at: Date().addingTimeInterval(debugOffset), subjectLookup: friendSubjectLookup)

				let friendBackground: Color = switch friendState {
					case let .beforeSchool(next):
						next.colour.swiftUIColor
					case let .inClass(current, _, _):
						current?.colour.swiftUIColor ?? .black
					case .inBreak:
						.orange
					case .outsideSchool:
						.black
				}

				return ScheduleItem(name: $0.sender, currentState: friendState, backgroundColour: friendBackground)
			}

			FriendsTimeLeftView(entry: entry, schedules: friendScheduleItems)
				.containerBackground(.black, for: .widget)
		}
		.contentMarginsDisabled()
		.configurationDisplayName("Friends Current Subjects")
		.description("Check what subjects your friends have right now, along with time left.")
		#if os(watchOS)
			.supportedFamilies([.accessoryRectangular])
		#else
			.supportedFamilies([.systemMedium])
		#endif
	}
}

#if os(watchOS)
	#Preview(as: .accessoryRectangular) {
		FriendsTimeLeftWidget()
	} timeline: {
		TimetableEntry(
			date: .now,
			subjects: debugTimetable,
			relevance: TimelineEntryRelevance(
				score: 1.0,
				duration: 60 * 60
			)
		)
	}
#else
	#Preview(as: .systemMedium) {
		FriendsTimeLeftWidget()
	} timeline: {
		TimetableEntry(
			date: .now,
			subjects: debugTimetable,
			relevance: TimelineEntryRelevance(
				score: 1.0,
				duration: 60 * 60
			)
		)
	}
#endif
