//
//  CurrentClassView.swift
//  Timetable Watch
//
//  Created by Adon Omeri on 11/6/2026.
//

import Defaults
import SwiftUI

struct CurrentClassView: View {
	@Default(.timetable) private var classes
	@Default(.displayMode) private var displayMode

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: classes)
		let state = getSchoolState(at: Date().addingTimeInterval(-45847), classLookup: classLookup)

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
	}

	private func createProgressView(title: String, symbol: String, color: Color, nextText: String, start: Date, end: Date) -> some View {
		GeometryReader { geo in
			ZStack {
				let total = end.timeIntervalSince(start)
				let elapsed = Date().addingTimeInterval(-45847).timeIntervalSince(start)
				let progress = total > 0 ? max(0, min(1, elapsed / total)) : 0
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

					Text(end, style: .timer)
						.contentTransition(.numericText())
						.font(.title2)
						.bold()
						.animation(.easeInOut(duration: 0.9), value: Date())
						.padding(5)
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
