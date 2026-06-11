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

	@State private var now = Date().addingTimeInterval(-45847)
	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: receivedTimetable.classes)
		let state = getSchoolState(at: now, classLookup: classLookup)

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
				let elapsed = now.timeIntervalSince(info.start)
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

				VStack(alignment: .leading) {
					Text(receivedTimetable.sender)
						.font(.title3)
						.bold()
						.lineLimit(1)
						.minimumScaleFactor(0.8)

					Spacer()

					Label(title, systemImage: symbol)
						.font(.body)
						.bold()

					Spacer()
						.frame(height: geo.size.height * 0.1)

					Text(!nextText.isEmpty ? nextText : "Done for the day")
						.font(.caption2)
						.foregroundStyle(.secondary)
				}
				.frame(width: geo.size.width)
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
