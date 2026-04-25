//
//  ContentView.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import Defaults
import SwiftUI

struct ContentView: View {
	let sessions = [
		"1",
		"2",
		"R",
		"3",
		"4",
		"L",
		"5",
		"6",
	]

	@Default(.timetable) var classes

	var body: some View {
		NavigationStack {
			VStack {
				HStack(spacing: 4) {
					VStack(spacing: 4) {
						Text("")

						ForEach(Array(sessions.enumerated()), id: \.offset) { _, session in
							if session == "R" || session == "L" {
								Text(session)
									.frame(height: 20)
									.foregroundStyle(.secondary)
							} else {
								Text(session)
									.frame(height: 60)
							}
						}
						.frame(width: 25)
					}
					.frame(width: 25)

					ForEach(0..<5) { day in
						VStack(spacing: 4) {
							Text(["Mon", "Tue", "Wed", "Thu", "Fri"][day])
							ForEach(0..<8) { session in
								if session == 2 || session == 5 {
									rectangle(.gray.opacity(0.25), true)
										.frame(height: 20)
								} else {
									if day == 2 && session == 7 || day == 4 && session == 7 {
										rectangle(.clear)
											.frame(height: 60)

									} else {
										if let c = classFor(day: day, session: session) {
											rectangle(
												c.colour.swiftUIColor.opacity(0.8)
											)
												.overlay(
													alignment: .leading
												) {
													VStack(alignment: .leading) {
														Image(systemName: c.symbol)
														Spacer(minLength: 0)
														Text(c.id)
															.lineLimit(2)
															.fixedSize(horizontal: false, vertical: true)
															.font(.footnote.scaled(by: 0.9))
													}
													.padding(5)
												}
												.frame(height: 60)

										} else {
											RoundedRectangle(cornerRadius: 0)
												.fill(
													LinearGradient(
														stops: [
															.init(color: .red, location: 0),
															.init(color: .blue, location: 0.5),
															.init(color: .red, location: 1),
														],
														startPoint: .leading,
														endPoint: .trailing
													)
												)
												.frame(height: 60)
										}
									}
								}
							}
						}
					}
				}
				Spacer()
			}
			.padding(.horizontal, 3)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button {

					} label: {
						Label("Edit Classes", systemImage: "pencil")
					}
				}
				ToolbarItem(placement: .title) {
					Text("PMS Timetable")
						.monospaced()
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button {} label: {
						Label("Sync", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
					}
					.buttonStyle(.glassProminent)
				}
			}
			.navigationBarTitleDisplayMode(.inline)
		}
		.environment(\.dynamicTypeSize, .xSmall)
		.monospaced()
	}

	func classFor(day: Int, session: Int) -> Class? {
		classes.first { c in
			c.slots.contains {
				$0.day == day && $0.session == session
			}
		}
	}
}

struct rectangle: View {
	let fill: Color

	let isBreak: Bool

	init(_ fill: Color, _ isBreak: Bool = false) {
		self.fill = fill
		self.isBreak = isBreak
	}

	var body: some View {
		RoundedRectangle(cornerRadius: isBreak ? 8 : 10)
			.fill(fill)
	}
}

#Preview {
	ContentView()
}
