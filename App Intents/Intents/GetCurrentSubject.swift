//
//   GetCurrentSubject.swift
//   App Intents
//
//   Created by Adon Omeri on 21/6/2026.
//

import AppIntents
import Defaults
import IrregularGradient
import SwiftUI

struct GetCurrentSubjectIntent: SnippetIntent {
	static var title: LocalizedStringResource = "Current Subject"

	static var description = IntentDescription("Shows your current subject")

	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

	static var supportedModes: IntentModes = .background

	static var isDiscoverable: Bool = true

	@MainActor
	func perform() async -> some IntentResult & ProvidesDialog & ShowsSnippetView {
		let subjects = Defaults[.timetable]

		let adjustedNow = TimetableClock.now
		let state = SchoolStateEngine.calculate(at: adjustedNow, subjects: subjects)

		let text: String = switch state {
			case .beforeSchool:
				"Before School"
			case let .lesson(lesson):
				lesson.subject.id
			case .freePeriod:
				"Free Period"
			case .recess:
				"Recess"
			case .lunch:
				"Lunch"
			case .afterSchool, .weekend:
				"Outside School Time"
			case .noTimetable:
				"No Timetable"
		}

		return .result(dialog: IntentDialog(stringLiteral: text), view: GetCurrentSubjectIntentView(state: state, now: adjustedNow))
	}
}

struct GetCurrentSubjectIntentView: View {
	let state: SchoolState

	let now: Date

	var body: some View {
		ZStack {
			VStack {
				Spacer()
				HStack {
					Spacer()
				}
			}

			switch state {
				case let .beforeSchool(next):
					createProgressView(
						title: next.subject.id,
						symbol: next.subject.symbol,
						color: next.subject.colour.swiftUIColor,
						nextText: nil,
						start: now,
						end: next.interval.start
					)

				case let .lesson(lesson):
					createProgressView(
						title: lesson.subject.id,
						symbol: lesson.subject.symbol,
						color: lesson.subject.colour.swiftUIColor,
						nextText: lesson.next.title,
						start: lesson.interval.start,
						end: lesson.interval.end
					)

				case let .freePeriod(period):
					createProgressView(
						title: "Free Period",
						symbol: "studentdesk",
						color: .blue,
						nextText: period.next.title,
						start: period.interval.start,
						end: period.interval.end
					)

				case let .recess(breakState):
					createProgressView(title: "Recess", symbol: BreakType.recess.symbol, color: .orange, nextText: breakState.next.title, start: breakState.interval.start, end: breakState.interval.end)

				case let .lunch(breakState):
					createProgressView(title: "Lunch", symbol: BreakType.lunch.symbol, color: .orange, nextText: breakState.next.title, start: breakState.interval.start, end: breakState.interval.end)

				case .afterSchool, .weekend:
					VStack(alignment: .leading) {
						Label("School's Out", systemImage: "house.fill")
							.font(.title)
							.padding(.bottom)

						Text("No more subjects")
							.foregroundStyle(.secondary)
					}
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)

				case .noTimetable:
					ContentUnavailableView("No Timetable", systemImage: "calendar.badge.exclamationmark")
			}
		}
		.background {
			Color.clear
				.overlay {
					GeometryReader { geo in
						switch state {
							case let .beforeSchool(next):
								createProgressBackground(
									color: next.subject.colour.swiftUIColor,
									start: nil,
									end: nil,
									geo: geo
								)

							case let .lesson(lesson):
								createProgressBackground(
									color: lesson.subject.colour.swiftUIColor,
									start: lesson.interval.start,
									end: lesson.interval.end,
									geo: geo
								)

							case let .freePeriod(period):
								createProgressBackground(color: .blue, start: period.interval.start, end: period.interval.end, geo: geo)

							case let .recess(state), let .lunch(state):
								createProgressBackground(
									color: .black,
									start: state.interval.start,
									end: state.interval.end,
									isBreak: true,
									geo: geo
								)

							case .afterSchool, .weekend, .noTimetable:
								ContainerRelativeShape()
									.fill(.black)
						}
					}
				}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.monospaced()
		.clipShape(ContainerRelativeShape())
	}

	private func createProgressView(
		title: String,
		symbol: String,
		color _: Color,
		nextText: String?,
		start _: Date?,
		end: Date?
	) -> some View {
		ZStack {
			Color.clear

			if let nextText, let end {
				let remaining = max(0, end.timeIntervalSince(now))
				let hours = Int(remaining) / 3600
				let minutes = (Int(remaining) % 3600) / 60
				let seconds = Int(remaining) % 60

				let timeString = hours > 0
					? String(format: "%d:%02d:%02d", hours, minutes, seconds)
					: String(format: "%02d:%02d", minutes, seconds)

				VStack(alignment: .leading) {
					HStack {
						Image(systemName: symbol)
						Text(title)
					}
					.font(.largeTitle)
					.lineLimit(2)
					.bold()

					Spacer(minLength: 50)

					HStack(alignment: .lastTextBaseline) {
						Text(timeString)
							.font(.largeTitle.scaled(by: 1.2))
							.lineLimit(1)
							.bold()

						Spacer()

						Text(nextText)
							.font(.body)
							.multilineTextAlignment(.center)
							.lineLimit(4)
							.layoutPriority(1)
					}
				}
			} else {
				VStack(alignment: .leading) {
					HStack(alignment: .lastTextBaseline) {
						Text("Before School")
							.font(.title)

						Spacer()

						let targetDate = Calendar.current.date(
							bySettingHour: 8,
							minute: 50,
							second: 0,
							of: now
						)!

						let remaining = max(0, targetDate.timeIntervalSince(now))
						let hours = Int(remaining) / 3600
						let minutes = (Int(remaining) % 3600) / 60
						let seconds = Int(remaining) % 60

						let timeString = hours > 0
							? String(format: "%d:%02d:%02d", hours, minutes, seconds)
							: String(format: "%02d:%02d", minutes, seconds)

						Text(timeString)
							.font(.title.scaled(by: 1.3))
							.bold()
					}

					Spacer(minLength: 50)

					Text("First Period:")
						.font(.body)
						.foregroundStyle(.secondary)

					HStack {
						Image(systemName: symbol)
						Text(title)
					}
					.font(.title.scaled(by: 1.2))
					.lineLimit(2)
					.bold()
				}
			}
		}
		.padding([.top, .horizontal])
		.padding(.bottom, 10)
	}

	private func createProgressBackground(color: Color, start: Date?, end: Date?, isBreak: Bool = false, geo: GeometryProxy) -> some View {
		Group {
			if let start, let end {
				let total = end.timeIntervalSince(start)
				let elapsed = now.timeIntervalSince(start)
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
								bottomTrailing: 20,
								topTrailing: 20
							)
						)
						.fill(fill)
						.frame(width: geo.size.width * progress)

						Rectangle()
							.fill(.clear)
					}
					.background {
						if !isBreak {
							ContainerRelativeShape()
								.fill(.black)
						}
					}
				}
			} else {
				Rectangle()
					.fill(color)
			}
		}
	}
}
