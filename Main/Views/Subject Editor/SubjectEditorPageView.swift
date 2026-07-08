//
//  SubjectEditorPageView.swift
//  Timetable
//
//  Created by Adon Omeri on 8/7/2026.
//

import SwiftUI

struct SubjectEditorPageView: View {
	@Binding var subject: EditableSubject

	let index: Int
	let isSaving: Bool

	let dayLabel: (Int) -> String
	let allowedPeriods: (Int) -> [Int]
	let canUse: (Int, Int) -> Bool

	let deleteSubject: (Int) -> Void
	let beginRenamingSubject: (Int) -> Void
	let selectSymbol: (EditableSubject.ID) -> Void

	var body: some View {
		VStack(spacing: 15) {
			SubjectHeaderRowView(
				subject: $subject,
				index: index,
				isSaving: isSaving,
				deleteSubject: deleteSubject,
				beginRenamingSubject: beginRenamingSubject
			)

			SubjectMetadataEditorView(subject: $subject)

			SymbolSelectionRowView(
				subject: subject,
				isSaving: isSaving,
				selectSymbol: selectSymbol
			)

			InlineColorPicker(selectedColor: selectedColorBinding)

			SlotEditorSectionView(
				subject: $subject,
				isSaving: isSaving,
				dayLabel: dayLabel,
				allowedPeriods: allowedPeriods,
				canUse: canUse
			)
			.animation(.spring(response: 0.3, dampingFraction: 0.8), value: subject.slots)

			Spacer()
		}
		#if os(iOS)
		.padding(.horizontal, 32)
		#else
		.padding(.horizontal, 20)
		.padding(.top, 10)
		#endif
	}

	private var selectedColorBinding: Binding<AvailableColors> {
		Binding(
			get: {
				closestColor(to: subject.color)
			},
			set: { newValue in
				subject.color = newValue.SwiftUIColor
			}
		)
	}
}
