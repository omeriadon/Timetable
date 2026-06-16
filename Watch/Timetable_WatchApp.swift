//
//  Timetable_WatchApp.swift
//  Timetable Watch Watch App
//
//  Created by Adon Omeri on 26/4/2026.
//

import Combine
import Defaults
import SwiftUI

let debugOffset: TimeInterval = 0

@main
struct TimetableWatchApp: App {
	@Default(.receivedTimetables) var receivedTimetables
	@Default(.timetable) var classes

	@State private var currentTab = 0
	@State private var now = Date()

	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	private var adjustedNow: Date {
		now.addingTimeInterval(debugOffset)
	}

	private var currentSchoolState: SchoolState {
		let classLookup = TimetableLayout.classLookup(for: classes)
		return getSchoolState(at: adjustedNow, classLookup: classLookup)
	}

	var body: some Scene {
		WindowGroup {
			TabView(selection: $currentTab) {
				Tab("Timetable", systemImage: "calendar", value: 0) {
					ContentView()
				}

				Tab("Current Class", systemImage: "timer", value: 1) {
					CurrentClassView(now: adjustedNow)
						.containerBackground(for: .tabView) {
							switch currentSchoolState {
								case let .beforeSchool(next):
									createProgressBackground(
										color: next.colour.swiftUIColor,
										start: nil,
										end: nil
									)

								case let .inClass(current, _, info):
									createProgressBackground(
										color: current?.colour.swiftUIColor ?? .blue,
										start: info.start,
										end: info.end
									)

								case let .inBreak(_, _, info):
									createProgressBackground(
										color: .orange,
										start: info.start,
										end: info.end
									)

								case .outsideSchool:
									Color.clear
							}
						}
				}

				ForEach(Array(receivedTimetables.enumerated()), id: \.offset) { index, receivedTimetable in
					Tab(receivedTimetable.sender, systemImage: "person", value: 2 + index) {
						FriendsTimetablesView(receivedTimetable: receivedTimetable)
							.containerBackground(for: .tabView) {
								switch currentSchoolState {
									case let .beforeSchool(next):
										createProgressBackground(
											color: next.colour.swiftUIColor,
											start: nil,
											end: nil
										)

									case let .inClass(current, _, info):
										createProgressBackground(
											color: current?.colour.swiftUIColor ?? .blue,
											start: info.start,
											end: info.end
										)

									case let .inBreak(_, _, info):
										createProgressBackground(
											color: .orange,
											start: info.start,
											end: info.end
										)

									case .outsideSchool:
										Color.clear
								}
							}
					}
				}
			}
			.onReceive(timer) { value in
				withAnimation(.easeInOut(duration: 0.5)) {
					now = value
				}
			}
			.monospaced()
			.tabViewStyle(.verticalPage)
		}
	}

	private func createProgressBackground(color: Color, start: Date?, end: Date?) -> some View {
		GeometryReader { geo in
			if let start = start, let end = end {
				let total = end.timeIntervalSince(start)
				let elapsed = adjustedNow.timeIntervalSince(start)
				let progress = total > 0 ? max(0, min(1, elapsed / total)) : 0

				HStack(spacing: 0) {
					Rectangle()
						.fill(color)
						.frame(width: geo.size.width * progress)

					Rectangle()
						.fill(.black)
				}
			} else {
				Rectangle()
					.fill(color)
			}
		}
	}
}
