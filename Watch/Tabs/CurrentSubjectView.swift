//
//   CurrentSubjectView.swift
//   Watch
//
//   Created by Adon Omeri on 11/6/2026.
//

import Combine
import Defaults
import SwiftUI

struct CurrentSubjectView: View {
	@Default(.timetable) private var subjects

	let now: Date

	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	var body: some View {
		let subjectLookup = TimetableLayout.subjectLookup(for: subjects)
		let state = getSchoolState(at: now, subjectLookup: subjectLookup)

		Group {
			switch state {
				case let .beforeSchool(next):
					createProgressView(
						title: next.id,
						symbol: next.symbol,
						color: next.colour.swiftUIColor,
						nextText: nil,
						start: nil,
						end: nil
					)

				case let .inClass(current, nextText, info):
					createProgressView(
						title: current?.id ?? "Free Period",
						symbol: current?.symbol ?? "studentdesk",
						color: current?.colour.swiftUIColor ?? .blue,
						nextText: nextText,
						start: info.start,
						end: info.end
					)

				case let .inBreak(breakType, nextText, info):
					createProgressView(
						title: breakType == .lunch ? "Lunch" : "Recess",
						symbol: breakType == .lunch
							? "takeoutbag.and.cup.and.straw.fill"
							: "cup.and.saucer.fill",
						color: .orange,
						nextText: nextText,
						start: info.start,
						end: info.end
					)

				case .outsideSchool:
					VStack(alignment: .center) {
						Label("School's Out", systemImage: "house.fill")
							.font(.title3)
							.padding(.bottom)

						Text("No more subjects")
							.foregroundStyle(.secondary)
					}
			}
		}
	}

	private func createProgressView(
		title: String,
		symbol: String,
		color: Color,
		nextText: String?,
		start _: Date?,
		end: Date?
	) -> some View {
		GeometryReader { geo in
			if let nextText, let end {
				// 2. Calculate remaining time using the synchronized parent 'now'
				let remaining = max(0, end.timeIntervalSince(now))
				let hours = Int(remaining) / 3600
				let minutes = (Int(remaining) % 3600) / 60
				let seconds = Int(remaining) % 60

				let timeString = hours > 0
					? String(format: "%d:%02d:%02d", hours, minutes, seconds)
					: String(format: "%02d:%02d", minutes, seconds)

				VStack(alignment: .center) {
					Spacer()
					Spacer()

					Image(systemName: symbol)
						.font(.title)
						.bold()

					Text(title)
						.font(.title2.scaled(by: 0.9))
						.lineLimit(2)
						.multilineTextAlignment(.center)
						.frame(maxWidth: geo.size.width * 0.9)
						.bold()

					Spacer()

					Text(timeString)
						.contentTransition(.numericText(countsDown: true))
						.animation(.easeInOut(duration: 0.5), value: timeString)
						.font(.title2)
						.lineLimit(1)
						.bold()
						.padding(.horizontal, 15)
						.padding(.vertical, 10)
						.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 10))

					Spacer()

					Text(nextText)
						.frame(maxWidth: geo.size.width * 0.8)
						.font(.caption)
						.multilineTextAlignment(.center)
						.foregroundStyle(.secondary)
						.lineLimit(4)
						.layoutPriority(1)

					Spacer()
						.frame(height: geo.size.height * 0.1)
				}
				.frame(width: geo.size.width)
			} else {
				VStack(alignment: .center) {
					Spacer()
					Spacer()

					Text("Before School")
						.font(.caption)
						.foregroundStyle(.secondary)
						.lineLimit(4)
						.layoutPriority(1)

					Spacer()

					Text("First Period:")
						.font(.caption2)
						.foregroundStyle(.secondary)

					Image(systemName: symbol)
						.font(.title)
						.bold()

					Text(title)
						.font(.title2.scaled(by: 0.9))
						.lineLimit(2)
						.multilineTextAlignment(.center)
						.frame(maxWidth: geo.size.width * 0.9)
						.bold()

					Spacer()

					let targetDate = Calendar.current.date(
						bySettingHour: 8,
						minute: 50,
						second: 0,
						of: Date()
					)!
					Text(timerInterval: Date.now ... targetDate, countsDown: true)
						.contentTransition(.numericText(countsDown: true))
						.animation(.easeInOut(duration: 0.5), value: Date.now)
						.font(.title2)
						.lineLimit(1)
						.bold()
						.padding(.horizontal, 15)
						.padding(.vertical, 10)
						.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 10))

					Spacer()
						.frame(height: geo.size.height * 0.1)
				}
			}
		}
		.ignoresSafeArea()
		.tint(color)
	}
}

#Preview {
	CurrentSubjectView(now: Date().addingTimeInterval(debugOffset))
		.monospaced()
}
