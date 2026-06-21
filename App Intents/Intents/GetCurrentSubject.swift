//
//  GetCurrentSubjectIntent.swift
//  Timetable
//
//  Created by Adon Omeri on 20/6/2026.
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

		let adjustedNow = Date().addingTimeInterval(debugOffset)

		let subjectLookup = TimetableLayout.subjectLookup(for: subjects)
		let state = getSchoolState(at: adjustedNow, subjectLookup: subjectLookup)

		let text: String = {
			switch state {
				case .beforeSchool:
					"Before School"
				case let .inClass(current, _, _):
					current?.id ?? "Unknown Subject"
				case let .inBreak(breakType, _, _):
					switch breakType {
						case .recess:
							"Recess"
						case .lunch:
							"Lunch"
					}
				case .outsideSchool:
					"Outside School Time"
			}
		}()

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
					VStack(alignment: .leading) {
						Label("School's Out", systemImage: "house.fill")
							.font(.title)
							.padding(.bottom)

						Text("No more subjects")
							.foregroundStyle(.secondary)
					}
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
		.background {
			Color.clear
				.overlay {
					GeometryReader { geo in
						switch state {
							case let .beforeSchool(next):
								createProgressBackground(
									color: next.colour.swiftUIColor,
									start: nil,
									end: nil,
									geo: geo
								)

							case let .inClass(current, _, info):
								createProgressBackground(
									color: current?.colour.swiftUIColor ?? .blue,
									start: info.start,
									end: info.end,
									geo: geo
								)

							case let .inBreak(_, _, info):
								createProgressBackground(
									color: .black,
									start: info.start,
									end: info.end,
									isBreak: true,
									geo: geo
								)

							case .outsideSchool:
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
								Color(red: 0.80, green: 0.60, blue: 1.0)
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
