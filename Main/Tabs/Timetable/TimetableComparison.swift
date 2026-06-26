//
//  TimetableComparison.swift
//  Timetable
//
//  Created by Adon Omeri on 11/6/2026.
//

import SwiftUI

struct TimetableComparison: View {
	@Environment(\.passManager) private var passManager

	let selectedSlot: Slot?

	var body: some View {
		VStack(spacing: 8) {
			ForEach(passManager.receivedTimetables.indices, id: \.self) { idx in
				if let slot = selectedSlot,
				   let theirSubject = getSubjectAtSlot(day: slot.day, session: slot.session, in: passManager.receivedTimetables[idx].subjects)
				{
					item(
						left: passManager.receivedTimetables[idx].sender,
						right: Label(theirSubject.id, systemImage: theirSubject.symbol),
						colour: theirSubject.colour.swiftUIColor
					)

				} else {
					item(
						left: passManager.receivedTimetables[idx].sender,
						right: Label("Free period", systemImage: "square.dotted"),
						colour: .gray
					)
				}
			}

			Spacer()
		}
		.padding()
	}

	func item(
		left: String,
		right: some View,
		colour: Color
	) -> some View {
		HStack {
			Text(left)

			Spacer()

			right
				.frame(height: 20)
				.padding(.trailing, 5)
		}
		.padding(15)
		.glassEffect(.clear.tint(colour).interactive(), in: Capsule())
	}

	private func getSubjectAtSlot(day: Int, session: Int, in timetable: [Subject]) -> Subject? {
		let subjectLookup = TimetableLayout.subjectLookup(for: timetable)
		return subjectLookup[Slot(day, session)]
	}
}

#Preview {
	TimetableComparison(selectedSlot: Slot(1, 2))
}
