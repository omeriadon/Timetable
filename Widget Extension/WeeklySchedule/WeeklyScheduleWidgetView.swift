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

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: classes)

		if classes.isEmpty {
			VStack(spacing: 4) {
				Text("No timetable")
					.font(.caption)
				Text("synced yet")
					.font(.caption)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color.gray.opacity(0.2))
		} else {
			HStack(spacing: 0) {
				ForEach(0 ..< 5) { day in
					VStack(spacing: 0) {
						HStack {
							Spacer()
							Text(TimetableLayout.shortDayLabels[day])
								.font(.footnote.scaled(by: 0.5))
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
			.environment(\.dynamicTypeSize, .xSmall)
			.monospaced()
		}
	}

	func sessionCell(_ day: Int, _ session: Int, classLookup: [Slot: Class]) -> some View {
		Group {
			if TimetableLayout.isBreakSession(index: session) {
				Text("")
					.font(.footnote.scaled(by: 0.1))
					.frame(height: 2)
			} else {
				if TimetableLayout.isUnavailable(day: day, session: session) {
					RoundedRectangle(cornerRadius: 0)
						.fill(.clear)
				} else {
					if let c = classLookup[Slot(day, session)] {
						if day == 0, session == 7 {
							VStack(alignment: .leading) {
								GeometryReader { geo in
									Text(c.id)
										.lineLimit(1)
										.font(.footnote.scaled(by: 0.5))
										.padding(.leading, day == currentWeekdayIndex ? 4 : 3)
										.fixedSize(horizontal: true, vertical: false)
										.padding(.trailing, 1)
										.frame(width: geo.size.width, alignment: .leading)
										.clipped()
										.allowsTightening(true)
								}
							}
							.padding(1)
							.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
							.foregroundStyle(.white)
							.background(
								RoundedRectangle(cornerRadius: 0)
									.fill(c.colour.swiftUIColor)
							)
						} else {
							VStack(alignment: .leading) {
								GeometryReader { geo in
									Text(c.id)
										.lineLimit(1)
										.font(.footnote.scaled(by: 0.5))
										.padding(.leading, day == currentWeekdayIndex ? 1 : 0)
										.fixedSize(horizontal: true, vertical: false)
										.padding(.trailing, 1)
										.frame(width: geo.size.width, alignment: .leading)
										.clipped()
										.allowsTightening(true)
								}
							}
							.padding(1)
							.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
							.foregroundStyle(.white)
							.background(
								RoundedRectangle(cornerRadius: 0)
									.fill(c.colour.swiftUIColor)
							)
						}
					} else {
						RoundedRectangle(cornerRadius: 0)
							.fill(.white.opacity(0.05))
					}
				}
			}
		}
		.foregroundStyle(.white)
	}

	private var currentWeekdayIndex: Int {
		let weekday = Calendar.current.component(.weekday, from: Date())
		// weekday: 1 = Sunday ... 7 = Saturday
		// convert to 0 = Monday ... 4 = Friday
		return (weekday + 5) % 7
	}
}
