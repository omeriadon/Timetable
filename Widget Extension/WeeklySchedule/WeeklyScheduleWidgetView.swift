//
//  WeeklyScheduleWidgetView.swift
//  Widget Extension
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SwiftUI

struct WeeklyScheduleWidgetView: View {
	let classes: [Class]

	// MARK: - body

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: classes)

		if classes.isEmpty {
			Text("No timetable synced yet")
				.lineLimit(2)

		} else {
			HStack(spacing: 0) {
				ForEach(0 ..< 5) { day in
					VStack(spacing: 0) {
						HStack {
							Spacer()

							Text(TimetableLayout.shortDayLabels[day])
								.padding(.vertical, Device.isNotWatchOS ? 5 : 0)
								.font(Device.isWatchOS ? .footnote.scaled(by: 0.5) : .caption)
								.frame(height: 10)

							Spacer()
						}
						.background(
							day == currentWeekdayIndex
								? Color.white
								: Color.clear
						)
						.foregroundStyle(
							day == currentWeekdayIndex
								? Color.black
								: Color.white
						)

						ForEach(0 ..< 8) { session in
							sessionCell(day, session, classLookup: classLookup)
						}

						Spacer(minLength: 0)
					}
					.overlay(alignment: .leading) {
						if day == currentWeekdayIndex {
							Rectangle()
								.fill(Color.white)
								.frame(width: 1)
						}
					}
					.overlay(alignment: .trailing) {
						if day == currentWeekdayIndex {
							Rectangle()
								.fill(Color.white)
								.frame(width: 1)
						}
					}
					.overlay(alignment: .bottom) {
						if day == currentWeekdayIndex {
							Rectangle()
								.fill(Color.white)
								.frame(height: 1)
						}
					}
				}
			}
			.padding([.bottom, .horizontal], Device.isNotWatchOS ? 8 : 0)
			.environment(\.dynamicTypeSize, .xSmall)
			.monospaced()
		}
	}

	// MARK: - sessionCell

	func sessionCell(_ day: Int, _ session: Int, classLookup: [Slot: Class]) -> some View {
		let leadingPadding: CGFloat = if day == 0, session == 7, Device.isWatchOS {
			day == currentWeekdayIndex ? 4 : 3
		} else {
			day == currentWeekdayIndex ? 1 : 0
		}

		return Group {
			// break
			if TimetableLayout.isBreakSession(index: session) {
				Text("")
					.font(.footnote.scaled(by: 0.1))
					.frame(height: 2)
			} else {
				// early finish
				if TimetableLayout.isUnavailable(day: day, session: session) {
					RoundedRectangle(cornerRadius: 0)
						.fill(.clear)
				} else {
					if let c = classLookup[Slot(day, session)] {
						GeometryReader { geo in
							Text(c.id)
								.lineLimit(1)
								.font(Device.isWatchOS ? .footnote.scaled(by: 0.5) : .callout)
								.padding(.leading, leadingPadding)
								.padding(.trailing, 1)
								.fixedSize(horizontal: true, vertical: false)
								.frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
								.clipped()
								.allowsTightening(true)
						}

						.padding(1)
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
						.foregroundStyle(.white)
						.background(
							RoundedRectangle(cornerRadius: Device.isWatchOS ? 0 : 7)
								.fill(c.colour.swiftUIColor)
						)

					} else {
						// empty period?
						RoundedRectangle(cornerRadius: 0)
							.fill(.clear)
					}
				}
			}
		}
		.padding(Device.isNotWatchOS ? 1 : 0)
		.foregroundStyle(.white)
	}

	// MARK: - currentWeekdayIndex

	private var currentWeekdayIndex: Int {
		let weekday = Calendar.current.component(.weekday, from: Date())
		// weekday: 1 = Sunday ... 7 = Saturday
		// convert to 0 = Monday ... 4 = Friday
		return (weekday + 5) % 7
	}
}

#Preview {
	WeeklyScheduleWidgetView(classes: defaultTimetable)
}
