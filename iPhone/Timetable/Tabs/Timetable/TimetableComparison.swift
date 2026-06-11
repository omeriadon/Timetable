//
//  TimetableComparisonshet.swift
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
		VStack(spacing: 20) {
			if let slot = selectedSlot,
			   let yourClass = getClassAtSlot(day: slot.day, session: slot.session, in: classes)
			{
				item(
					left: "You",
					right: Label(yourClass.id, systemImage: yourClass.symbol),
					colour: yourClass.colour.swiftUIColor
				)

			} else {
				item(
					left: "You",
					right: Label("Free Period", systemImage: "square.dotted"),
					colour: .gray
				)
			}

			Divider()

			Text("Other Timetables")
				.font(.title3)

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
			}

			Spacer()
		}
		.padding()
	}

	func item<Right: View>(
		left: String,
		right: Right,
		colour: Color
	) -> some View {
		HStack {
			Text(left)

			Spacer()

			right
				.frame(height: 20)
				.padding(.trailing, 10)
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
