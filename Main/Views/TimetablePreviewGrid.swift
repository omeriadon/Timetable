import SwiftUI

struct TimetablePreviewGrid: View {
	let subjects: [Subject]

	var body: some View {
		let lookup = TimetableLayout.subjectLookup(for: subjects)
		Grid(horizontalSpacing: 4, verticalSpacing: 4) {
			GridRow {
				Color.clear.frame(width: 18, height: 1)
				ForEach(TimetableLayout.shortDayLabels, id: \.self) { Text($0).font(.caption2).foregroundStyle(.secondary) }
			}
			ForEach(0 ..< 8, id: \.self) { session in
				GridRow {
					Text("\(session + 1)").font(.caption2).foregroundStyle(.secondary).frame(width: 18)
					ForEach(0 ..< 5, id: \.self) { day in
						if let subject = lookup[Slot(day, session)] {
							RoundedRectangle(cornerRadius: 8)
								.fill(subject.colour.swiftUIColor.opacity(0.8))
								.overlay { Image(systemName: subject.symbol).font(.caption).foregroundStyle(.white) }
								.frame(minWidth: 42, minHeight: 44)
						} else {
							RoundedRectangle(cornerRadius: 8).fill(.secondary.opacity(0.08)).frame(minWidth: 42, minHeight: 44)
						}
					}
				}
			}
		}
		.accessibilityElement(children: .ignore)
		.accessibilityLabel("Weekly timetable preview with \(subjects.count) subjects")
	}
}
