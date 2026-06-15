//
//  TimetableComparison.swift
//  Timetable
//
//  Created by Adon Omeri on 11/6/2026.
//

import Defaults
import SwiftUI

struct TimetableComparison: View {
	@Default(.receivedTimetables) var receivedTimetables
	@Default(.timetable) var classes

	let selectedSlot: Slot?

	var body: some View {
		VStack(spacing: 8) {
			ForEach(receivedTimetables.indices, id: \.self) { idx in
				if let slot = selectedSlot,
				   let theirClass = getClassAtSlot(day: slot.day, session: slot.session, in: receivedTimetables[idx].classes)
				{
					item(
						left: receivedTimetables[idx].sender,
						right: Label(theirClass.id, systemImage: theirClass.symbol),
						colour: theirClass.colour.swiftUIColor
					)

				} else {
					item(
						left: receivedTimetables[idx].sender,
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

	private func getClassAtSlot(day: Int, session: Int, in timetable: [Class]) -> Class? {
		let classLookup = TimetableLayout.classLookup(for: timetable)
		return classLookup[Slot(day, session)]
	}
}

#Preview {
	TimetableComparison(selectedSlot: Slot(1, 2))
}
