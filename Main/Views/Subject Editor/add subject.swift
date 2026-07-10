//
//  add subject.swift
//  Timetable
//
//  Created by Adon Omeri on 8/7/2026.
//

import SwiftUI

struct AddSubjectPageView: View {
	let pendingPrefillSlot: EditableSlot?
	let isSaving: Bool
	let dayLabel: (Int) -> String
	let addNewSubject: () -> Void

	var body: some View {
		VStack(spacing: 16) {
			Spacer()

			Button {
				withAnimation {
					addNewSubject()
				}
			} label: {
				ZStack {
					RoundedRectangle(cornerRadius: 24)
						.fill(.white.opacity(0.08))
						.frame(width: 180, height: 180)

					Image(systemName: "plus")
						.font(.system(size: 48, weight: .semibold))
				}
			}
			.buttonStyle(.plain)
			.disabled(isSaving)

			Text("Add New Subject")
				.font(.headline)

			if let pendingPrefillSlot {
				Text("Will prefill \(dayLabel(pendingPrefillSlot.day)) Period \(pendingPrefillSlot.period)")
					.foregroundStyle(.secondary)
			}

			Spacer()
		}
	}
}
