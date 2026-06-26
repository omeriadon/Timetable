//
//  FriendsTimeLeftWidget.swift
//  Shared Widget
//
//  Created by Adon Omeri on 27/4/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct FriendsTimeLeftWidget: Widget {
	let kind: String = "FriendsTimeLeft"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			let subjectLookup = TimetableLayout.subjectLookup(for: entry.subject)
			let state = getSchoolState(at: entry.date, subjectLookup: subjectLookup)

			let background: Color = switch state {
				case let .beforeSchool(next):
					next.colour.swiftUIColor
				case let .inClass(current, _, _):
					current?.colour.swiftUIColor ?? .black
				case .inBreak:
						.orange
				case .outsideSchool:
						.black
			}

			TimeLeftView(entry: entry, state: state)
				.containerBackground(background, for: .widget)
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
			subject: debugTimetable,
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
			subject: debugTimetable,
			relevance: TimelineEntryRelevance(
				score: 1.0,
				duration: 60 * 60
			)
		)
	}
#endif
