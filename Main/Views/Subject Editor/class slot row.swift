//
//  class slot row.swift
//  Timetable
//
//  Created by Adon Omeri on 8/7/2026.
//

import SwiftUI

struct SlotRowView: View {
	@Binding var slot: EditableSlot

	let isSaving: Bool
	let dayLabel: (Int) -> String
	let allowedPeriods: (Int) -> [Int]
	let canUse: (Int, Int) -> Bool
	let deleteSlot: () -> Void

	var body: some View {
		HStack {
			Picker("Day:", selection: $slot.day) {
				ForEach(0 ..< 5, id: \.self) { day in
					Text(dayLabel(day)).tag(day)
				}
			}
			.tint(.white)
			.frame(width: 140, alignment: .leading)
			.pickerStyle(.menu)
			.disabled(isSaving)
			.onChange(of: slot.day) { _, newDay in
				if !canUse(slot.period, newDay) {
					slot.period = 5
				}
			}

			Spacer()

			Picker("Period:", selection: $slot.period) {
				ForEach(allowedPeriods(slot.day), id: \.self) { period in
					Text("Period \(period)").tag(period)
				}
			}
			.tint(.white)
			.frame(width: 120)
			.pickerStyle(.menu)
			.disabled(isSaving)

			Spacer()

			Button(role: .destructive) {
				deleteSlot()
			} label: {
				Image(systemName: "trash")
			}
			.frame(width: 20)
			.buttonStyle(.glassProminent)
			.buttonBorderShape(.circle)
			.disabled(isSaving)
		}
	}
}
