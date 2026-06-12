import SwiftUI
import WidgetKit

struct Time_Left_Widget_View: View {
	let entry: TimetableEntry

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: entry.classes)
		let state = getSchoolState(at: entry.date, classLookup: classLookup)

		Group {
			switch state {
				case let .inClass(current, nextText, info):
					createProgressView(
						title: current?.id ?? "Free Period",
						symbol: current?.symbol ?? "studentdesk",
						color: current?.colour.swiftUIColor ?? .gray,
						nextText: nextText,
						start: info.start,
						end: info.end
					)

				case let .inBreak(title, nextText, info):
					createProgressView(
						title: title,
						symbol: title == "Lunch" ? "takeoutbag.and.cup.and.straw.fill" : "cup.and.saucer.fill",
						color: .orange,
						nextText: nextText,
						start: info.start,
						end: info.end
					)

				case .outsideSchool:
					VStack(alignment: .leading) {
						Label("School's Out", systemImage: "house.fill")
							.font(.headline)
							.foregroundColor(.indigo)

						Text("No more classes")
							.font(.system(size: 10))
							.foregroundColor(.secondary)
					}
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
		ZStack(alignment: .leading) {
			GeometryReader { geo in
				let total = end.timeIntervalSince(start)
				let elapsed = Date().timeIntervalSince(start)
				let progress = total > 0 ? max(0, min(1, elapsed / total)) : 0

				VStack {
					Rectangle()
						.fill(color)
						.frame(width: geo.size.width * progress)

					Spacer(minLength: 0)
				}
			}
			.tint(color)
			.widgetAccentable()

			VStack(alignment: .leading) {
				Label(title, systemImage: symbol)
					.font(.headline)
					.lineLimit(1)

				Spacer(minLength: 1)

				Text(end, style: .timer)
					.font(.system(.body, design: .monospaced))

				Spacer(minLength: 1)

				Text(nextText)
					.font(.body.scaled(by: 0.9))
					.foregroundStyle(.secondary)
					.lineLimit(1)
			}
			.padding([.vertical, .leading])
		}
	}
}

#Preview {
	Time_Left_Widget_View(
		entry: TimetableEntry(
			date: Date(),
			classes: defaultTimetable,
			relevance: TimelineEntryRelevance(score: 1, duration: 60 * 60)
		)
	)
}
