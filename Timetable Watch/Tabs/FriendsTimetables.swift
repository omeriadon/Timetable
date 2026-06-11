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

//	#if DEBUG
//		private let debugOffset: TimeInterval = -45647
//	#else
		private let debugOffset: TimeInterval = 0
//	#endif

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
		let progressInfo: (start: Date, end: Date)?

		switch state {
			case let .inClass(current, next, info):
				title = current?.id ?? "Free Period"
				symbol = current?.symbol ?? "studentdesk"
				color = current?.colour.swiftUIColor ?? .blue
				nextText = next
				progressInfo = info

			case let .inBreak(breakTitle, next, info):
				title = breakTitle
				symbol = breakTitle == "Lunch"
					? "takeoutbag.and.cup.and.straw.fill"
					: "cup.and.saucer.fill"
				color = .orange
				nextText = next
				progressInfo = info

			case .outsideSchool:
				title = "School's Out"
				symbol = "house.fill"
				color = .secondary
				progressInfo = nil
		}

		return GeometryReader { geo in
			let progress: CGFloat = {
				guard let info = progressInfo else { return 0 }
				let total = info.end.timeIntervalSince(info.start)
				let elapsed = adjustedNow.timeIntervalSince(info.start) // Respects the offset
				return total > 0 ? max(0, min(1, elapsed / total)) : 0
			}()

			ZStack {
				HStack(spacing: 0) {
					Rectangle()
						.fill(color.opacity(0.35))
						.frame(width: geo.size.width * progress)

					Spacer(minLength: 0)
				}
				.ignoresSafeArea()

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
				.padding(.leading)
			}
		}
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
