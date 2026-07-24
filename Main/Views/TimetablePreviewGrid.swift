import SwiftUI

let sessionLabels = ["1", "2", "R", "3", "4", "L", "5", "6"]

struct TimetablePreviewGrid: View {
	let subjects: [Subject]

	var body: some View {
		let lookup = TimetableLayout.subjectLookup(for: subjects)

		Grid(horizontalSpacing: 4, verticalSpacing: 4) {
			GridRow {
				Color.clear
					.frame(width: 8, height: 1)

				ForEach(TimetableLayout.shortDayLabels, id: \.self) {
					Text($0)
						.font(.caption2)
						.foregroundStyle(.secondary)
				}
			}

			ForEach(0 ..< 8, id: \.self) { session in
				let isBreak = session == 2 || session == 5
				let cellHeight: CGFloat = isBreak ? 22 : 44

				GridRow {
					Text(sessionLabels[session])
						.font(.caption2)
						.foregroundStyle(.secondary)
						.frame(width: 8)

					ForEach(0 ..< 5, id: \.self) { day in
						if isBreak {
							Color.clear
								.frame(minWidth: 42, minHeight: cellHeight)
						} else if let subject = lookup[Slot(day, session)] {
							RoundedRectangle(cornerRadius: 8)
								.fill(subject.colour.swiftUIColor.opacity(0.8))
								.overlay {
									Image(systemName: subject.symbol)
										.font(.caption)
										.foregroundStyle(.white)
								}
								.frame(minWidth: 42, minHeight: cellHeight)
						} else {
							RoundedRectangle(cornerRadius: 8)
								.fill(
									session == 7 && (day == 2 || day == 4)
										? .clear
										: .secondary.opacity(0.08)
								)
								.frame(minWidth: 42, minHeight: cellHeight)
						}
					}
				}
			}
		}
		.accessibilityElement(children: .ignore)
		.accessibilityLabel("Weekly timetable preview with \(subjects.count) subjects")
	}
}
