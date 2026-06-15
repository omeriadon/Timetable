//
//  FriendsTimetables.swift
//  Timetable Watch
//
//  Created by Adon Omeri on 11/6/2026.
//

import Combine
import Defaults
import SwiftUI

struct FriendsTimetables: View {
	let receivedTimetable: ReceivedTimetable

	@State private var now = Date()
	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	private var adjustedNow: Date {
		now.addingTimeInterval(debugOffset)
	}

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: receivedTimetable.classes)
		let state = getSchoolState(at: adjustedNow, classLookup: classLookup)

		let title: String
		let symbol: String
		let color: Color
		var nextText = ""

		switch state {
			case let .inClass(current, next, _):
				title = current?.id ?? "Free Period"
				symbol = current?.symbol ?? "studentdesk"
				color = current?.colour.swiftUIColor ?? .blue
				nextText = next

			case let .inBreak(breakTitle, next, _):
				title = breakTitle
				symbol = breakTitle == "Lunch"
					? "takeoutbag.and.cup.and.straw.fill"
					: "cup.and.saucer.fill"
				color = .orange
				nextText = next

			case .outsideSchool:
				title = "School's Out"
				symbol = "house.fill"
				color = .secondary
		}

		return GeometryReader { geo in
			VStack(alignment: .center) {
				Text(receivedTimetable.sender)
					.font(.title2)
					.bold()
					.lineLimit(2)
					.minimumScaleFactor(0.8)

				Spacer()

				HStack {
					Image(systemName: symbol)
					Text(title)
				}
				.font(.body.scaled(by: 1.2))
				.bold()

				Spacer()
					.frame(height: geo.size.height * 0.1)

				Text(!nextText.isEmpty ? nextText : "Done for the day")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			.frame(width: geo.size.width)
		}
		.dynamicTypeSize(.xSmall)
		.tint(color)
		.onReceive(timer) { value in
			withAnimation(.default) {
				now = value
			}
		}
	}
}

#Preview {
	FriendsTimetables(
		receivedTimetable: ReceivedTimetable(
			sender: "Adon Omeri",
			classes: defaultTimetable,
			receivedAt: Date()
		)
	)
	.monospaced()
}
