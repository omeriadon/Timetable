import SwiftUI

struct SchoolDatesView: View {
	let schoolCalendar: SchoolCalendarProjection

	private let calendar = SchoolCalendarProjection.perthCalendar

	var body: some View {
		let window = dateWindow
		List {
			Section("Term Dates") {
				ForEach(Array(schoolCalendar.termRanges.enumerated()), id: \.offset) { _, range in
					if range.intersects(window, calendar: calendar) {
						LabeledContent(range.label) {
							Text(range.displayLabel(calendar: calendar))
								.multilineTextAlignment(.trailing)
								.foregroundStyle(.secondary)
						}
					}
				}
				if schoolCalendar.termRanges.allSatisfy({ !$0.intersects(window, calendar: calendar) }) {
					ContentUnavailableView("No Term Dates", systemImage: "calendar")
				}
			}

			Section("No School") {
				let skippedDates = schoolCalendar.skippedDates.filter { window.contains($0.date) }.sorted { $0.date < $1.date }
				if skippedDates.isEmpty {
					Text("No no-school days upcoming.")
						.foregroundStyle(.secondary)
				} else {
					ForEach(skippedDates, id: \.self) { date in
						Label(date.label, systemImage: "moon.zzz")
					}
				}
			}
		}
	}

	private var dateWindow: ClosedRange<SchoolCalendarDate> {
		let start = SchoolCalendarDate(TimetableClock.now, calendar: calendar)
		let endDate = calendar.date(byAdding: .month, value: 3, to: TimetableClock.now) ?? TimetableClock.now
		return start ... SchoolCalendarDate(endDate, calendar: calendar)
	}
}

private extension SchoolCalendarDateRange {
	func intersects(_ window: ClosedRange<SchoolCalendarDate>, calendar _: Calendar) -> Bool {
		start <= window.upperBound && end >= window.lowerBound
	}

	func displayLabel(calendar: Calendar) -> String {
		guard let startDate = start.startOfDay(calendar: calendar), let endDate = end.startOfDay(calendar: calendar) else { return "" }
		return "\(startDate.formatted(.dateTime.day().month(.abbreviated))) – \(endDate.formatted(.dateTime.day().month(.abbreviated).year()))"
	}
}
