//
//  CurrentClassView.swift
//  Timetable Watch
//
//  Created by Adon Omeri on 11/6/2026.
//

import Combine
import Defaults
import SwiftUI

struct CurrentClassView: View {
	@Default(.timetable) private var classes
	@Default(.displayMode) private var displayMode

	@State private var now = Date()

	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	#if DEBUG
		private let debugOffset: TimeInterval = -45847
	#else
		private let debugOffset: TimeInterval = 0
	#endif

	private var adjustedNow: Date {
		now.addingTimeInterval(debugOffset)
	}

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: classes)
		let state = getSchoolState(at: adjustedNow, classLookup: classLookup)

		Group {
			switch state {
				case let .inClass(current, nextText, info):
					createProgressView(
						title: current?.id ?? "Free Period",
						symbol: current?.symbol ?? "studentdesk",
						color: current?.colour.swiftUIColor ?? .blue,
						nextText: nextText,
						start: info.start,
						end: info.end
					)

				case let .inBreak(title, nextText, info):
					createProgressView(
						title: title,
						symbol: title == "Lunch"
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

						Text("No more classes")
							.foregroundStyle(.secondary)
					}
			}
		}
		.onReceive(timer) { value in
			withAnimation(.easeInOut(duration: 0.5)) {
				now = value
			}
		}
	}

	private func createProgressView(
		title: String,
		symbol: String,
		color: Color,
		nextText: String,
		start: Date,
		end: Date
	) -> some View {
		GeometryReader { geo in
			let total = end.timeIntervalSince(start)
			let elapsed = adjustedNow.timeIntervalSince(start)
			let progress = total > 0 ? max(0, min(1, elapsed / total)) : 0

			let realStart = start.addingTimeInterval(-debugOffset)
			let realEnd = end.addingTimeInterval(-debugOffset)
			let safeRealEnd = max(realEnd, realStart.addingTimeInterval(1))

			let remaining = max(0, safeRealEnd.timeIntervalSince(now))
			let hours = Int(remaining) / 3600
			let minutes = (Int(remaining) % 3600) / 60
			let seconds = Int(remaining) % 60

			let timeString = hours > 0
				? String(format: "%d:%02d:%02d", hours, minutes, seconds)
				: String(format: "%02d:%02d", minutes, seconds)

			ZStack {
				HStack(spacing: 0) {
					Rectangle()
						.fill(color)
						.frame(width: geo.size.width * progress)

					Spacer(minLength: 0)
				}

				VStack(alignment: .center) {
					Label(title, systemImage: symbol)

					Spacer()
						.frame(height: geo.size.height * 0.15)

					Text(timeString)
						.contentTransition(.numericText(countsDown: true))
						.font(.title2)
						.bold()
						.padding(.horizontal, 15)
						.padding(.vertical, 10)
						.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 10))

					Spacer()
						.frame(height: geo.size.height * 0.15)

					Text(nextText)
						.frame(maxWidth: geo.size.width * 0.8)
						.font(.caption)
						.foregroundStyle(.secondary)
						.lineLimit(4)
						.layoutPriority(1)
				}
				.padding(.top, geo.size.height * 0.2)
			}
			.ignoresSafeArea()
		}
		.tint(color)
	}
}

#Preview {
	CurrentClassView()
		.monospaced()
}
