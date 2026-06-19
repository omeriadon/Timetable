//
//  WeeklyScheduleView.swift
//  Widget Extension
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SwiftUI
import WidgetKit

struct WeeklyScheduleView: View {
	@Default(.timetable) var classes

	@Environment(\.widgetRenderingMode) var widgetRenderingMode

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
								.font(Device.isWatchOS ? .footnote.scaled(by: 0.5) : .callout)
								.frame(height: Device.isWatchOS ? 10 : 20)
								.blendMode(day == currentWeekdayIndex && Device.isNotWatchOS ? .destinationOut : .normal)

							Spacer()
						}
						.background {
							if day == currentWeekdayIndex, Device.isNotWatchOS {
								Rectangle()
									.fill(widgetRenderingMode != .fullColor ? Color.secondary : Color.white)
									.clipShape(
										UnevenRoundedRectangle(
											cornerRadii: .init(
												topLeading: 0,
												bottomLeading: 7,
												bottomTrailing: 7,
												topTrailing: 0
											)
										)
									)
									.padding(.bottom, 1)
							}
						}
						.background(
							day == currentWeekdayIndex && Device.isWatchOS
								? Color.white
								: Color.clear
						)
						.foregroundStyle(
							day == currentWeekdayIndex && Device.isWatchOS
								? Color.black
								: Color.white
						)

						ForEach(0 ..< 8) { session in
							sessionCell(day, session, classLookup: classLookup)
						}

						Spacer(minLength: 0)
					}
					.overlay(alignment: .leading) {
						if day == currentWeekdayIndex, Device.isWatchOS {
							Rectangle()
								.fill(Color.white)
								.frame(width: 1)
						}
					}
					.overlay(alignment: .trailing) {
						if day == currentWeekdayIndex, Device.isWatchOS {
							Rectangle()
								.fill(Color.white)
								.frame(width: 1)
						}
					}
					.overlay(alignment: .bottom) {
						if day == currentWeekdayIndex, Device.isWatchOS {
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

	@ViewBuilder
	func sessionCell(_ day: Int, _ session: Int, classLookup: [Slot: Class]) -> some View {
		let leadingPadding: CGFloat =
			if day == 0, session == 7, Device.isWatchOS {
				day == currentWeekdayIndex ? 5 : 4
			} else {
				if Device.isWatchOS {
					day == currentWeekdayIndex ? 1 : 0
				} else {
					day == currentWeekdayIndex ? 3 : 4
				}
			}

		let isFullColor = widgetRenderingMode == .fullColor

		ZStack {
			// break
			if TimetableLayout.isBreakSession(index: session) {
				Text("")
					.font(.footnote.scaled(by: 0.1))
					.frame(height: Device.isWatchOS ? 2 : 1)
			} else {
				// early finish
				if TimetableLayout.isUnavailable(day: day, session: session) {
					RoundedRectangle(cornerRadius: 0)
						.fill(.clear)
				} else {
					if let c = classLookup[Slot(day, session)] {
						GeometryReader { geo in
							Text(c.id)
								.foregroundStyle(.white)
								.lineLimit(1)
								.font(Device.isWatchOS ? .footnote.scaled(by: 0.5) : .footnote)
								.padding(.leading, leadingPadding)
								.allowsTightening(true)
								.fixedSize(horizontal: true, vertical: false)
								.frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
								.blendMode(
									day == currentWeekdayIndex &&
										Device.isNotWatchOS &&
										widgetRenderingMode != .fullColor
										? .destinationOut : .normal
								)
								.clipped()
								.padding(.trailing, 1)
						}
						.padding(1)
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
						.background {
							if day == currentWeekdayIndex {
								if isFullColor {
									RoundedRectangle(cornerRadius: Device.isWatchOS ? 0 : 7)
										.fill(c.colour.swiftUIColor)
								} else {
									RoundedRectangle(cornerRadius: Device.isWatchOS ? 0 : 7)
										.fill(c.colour.swiftUIColor.secondary)
								}
							} else {
								if isFullColor {
									RoundedRectangle(cornerRadius: Device.isWatchOS ? 0 : 7)
										.fill(c.colour.swiftUIColor)
								} else {
									RoundedRectangle(cornerRadius: Device.isWatchOS ? 0 : 7)
										.stroke(c.colour.swiftUIColor.secondary)
								}
							}
						}

					} else {
						// empty period?
						RoundedRectangle(cornerRadius: 0)
							.fill(.clear)
					}
				}
			}
		}
		.compositingGroup()
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
	WeeklyScheduleView()
}
