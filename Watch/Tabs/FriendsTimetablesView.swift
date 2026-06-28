//
//   FriendsTimetablesView.swift
//   Watch
//
//   Created by Adon Omeri on 11/6/2026.
//

import Combine
import Defaults
import SwiftUI

struct FriendsTimetablesView: View {
	let receivedTimetable: ReceivedTimetable

	@State private var now = Date()
	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	private var adjustedNow: Date {
		now.addingTimeInterval(debugOffset)
	}

	var body: some View {
		let subjectLookup = TimetableLayout.subjectLookup(for: receivedTimetable.subjects)
		let state = getSchoolState(at: adjustedNow, subjectLookup: subjectLookup)

		let title: String
		let symbol: String
		let color: Color
		var nextText = ""

		switch state {
			case let .beforeSchool(next):
				title = next.id
				symbol = next.symbol
				color = next.colour.swiftUIColor
				nextText = ""

			case let .inClass(current, next, _):
				title = current?.id ?? "Free Period"
				symbol = current?.symbol ?? "studentdesk"
				color = current?.colour.swiftUIColor ?? .blue
				nextText = next

			case let .inBreak(breakType, next, _):
				title = breakType == .lunch ? "Lunch" : "Recess"
				symbol = breakType == .lunch
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
				.font(.title2.scaled(by: 0.9))
				.bold()

				Spacer()

				let isAfter850 = Date().addingTimeInterval(debugOffset) >= Calendar.current.date(
					bySettingHour: 8,
					minute: 50,
					second: 0,
					of: Date()
				)!

				Text(!nextText.isEmpty ? nextText : isAfter850 ? "Done for the day" : "")
					.font(.caption)
					.foregroundStyle(.secondary)
					.frame(maxWidth: geo.size.width * 0.8)
					.multilineTextAlignment(.center)

				Spacer()
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
	FriendsTimetablesView(
		receivedTimetable: ReceivedTimetable(
			sender: "Adon Omeri",
			subjects: debugTimetable,
			receivedAt: Date()
		)
	)
	.monospaced()
}
