//
//  SlotEditorSectionView.swift
//  Timetable
//
//  Created by Adon Omeri on 8/7/2026.
//

import SwiftUI

struct SlotEditorSectionView: View {
	@Binding var subject: EditableSubject

	let isSaving: Bool
	let dayLabel: (Int) -> String
	let allowedPeriods: (Int) -> [Int]
	let canUse: (Int, Int) -> Bool

	var body: some View {
		VStack(alignment: .leading) {
			ForEach($subject.slots) { $slot in
				SlotRowView(
					slot: $slot,
					isSaving: isSaving,
					dayLabel: dayLabel,
					allowedPeriods: allowedPeriods,
					canUse: canUse,
					deleteSlot: {
						subject.slots.removeAll { $0.id == slot.id }
					}
				)
				.transition(.scale.combined(with: .opacity))
			}

			if subject.slots.count < 4 {
				Button {
					subject.slots.append(
						EditableSlot(day: 0, period: TimetableLayout.allowedPeriods(for: 0).first ?? 1)
					)
				} label: {
					Label("Add Slot", systemImage: "plus")
				}
				.buttonStyle(.glass)
				.buttonBorderShape(.capsule)
				.disabled(isSaving)
			}
		}
	}
}
