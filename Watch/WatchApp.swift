//
//   WatchApp.swift
//   Watch
//
//   Created by Adon Omeri on 26/4/2026.
//

import Combine
import Defaults
import IrregularGradient
import SwiftUI

@main
struct TimetableWatchApp: App {
	@Default(.timetable) var subjects

	@Default(.receivedTimetables) private var receivedTimetables
	@State private var sessionStore = SessionStore.shared

	@State private var currentTab = 0
	@State private var now = Date()

	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

	private var adjustedNow: Date {
		now.addingTimeInterval(debugOffset)
	}

	private var currentSchoolState: SchoolState {
		let subjectLookup = TimetableLayout.subjectLookup(for: subjects)
		return getSchoolState(at: adjustedNow, subjectLookup: subjectLookup)
	}

	var body: some Scene {
		WindowGroup {
			TabView(selection: $currentTab) {
				Tab("Timetable", systemImage: "calendar", value: 0) {
					ContentView()
				}

				Tab("Current Subject", systemImage: "timer", value: 1) {
					CurrentSubjectView(now: adjustedNow)
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
										color: .black,
										start: info.start,
										end: info.end,
										isBreak: true
									)

								case .outsideSchool:
									Color.clear
							}
						}
				}

				ForEach(Array(receivedTimetables.enumerated()), id: \.element.id) { index, receivedTimetable in
					Tab(receivedTimetable.sender, systemImage: "person", value: 2 + index) {
						let friendLookup = TimetableLayout.subjectLookup(for: receivedTimetable.subjects)

						let friendState = getSchoolState(
							at: adjustedNow,
							subjectLookup: friendLookup
						)

						FriendsTimetablesView(receivedTimetable: receivedTimetable)
							.containerBackground(for: .tabView) {
								switch friendState {
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
											color: .black,
											start: info.start,
											end: info.end,
											isBreak: true
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
			.task {
				SessionStore.shared.configureAccountBootstrap { try await WatchAccountBootstrapService.shared.bootstrap() }
				NetworkManager.shared.startMonitoring()
				await SessionStore.shared.restore()
			}
		}
	}

	private func createProgressBackground(color: Color, start: Date?, end: Date?, isBreak: Bool = false) -> some View {
		GeometryReader { geo in
			if let start, let end {
				let total = end.timeIntervalSince(start)
				let elapsed = adjustedNow.timeIntervalSince(start)
				let progress = total > 0 ? max(0, min(1, elapsed / total)) : 0

				ZStack {
					if isBreak {
						IrregularGradient(
							colors: [
								.yellow,
								.orange,
								.pink,
								.red,
								.purple,
								.blue,
								.cyan,
								.mint,
								.green,
								Color(red: 1.0, green: 0.84, blue: 0.0),
								Color(red: 1.0, green: 0.72, blue: 0.82),
								Color(red: 0.60, green: 0.90, blue: 1.0),
								Color(red: 0.70, green: 1.0, blue: 0.70),
								Color(red: 1.0, green: 0.60, blue: 0.40),
								Color(red: 0.80, green: 0.60, blue: 1.0),
							],
							background: Color.blue,
							speed: 2,
							animate: true
						)
						.frame(width: geo.size.width, height: geo.size.height)
					}

					HStack(spacing: 0) {
						let fill: AnyShapeStyle = isBreak
							? AnyShapeStyle(.thinMaterial)
							: AnyShapeStyle(color)

						UnevenRoundedRectangle(
							cornerRadii: RectangleCornerRadii(
								topLeading: 0,
								bottomLeading: 0,
								bottomTrailing: 30,
								topTrailing: 30
							)
						)
						.fill(fill)
						.frame(width: geo.size.width * progress)

						Rectangle()
							.fill(.clear)
					}
				}
			} else {
				Rectangle()
					.fill(color)
			}
		}
	}
}
