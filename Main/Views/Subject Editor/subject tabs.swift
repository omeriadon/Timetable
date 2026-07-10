//
//  subject tabs.swift
//  Timetable
//
//  Created by Adon Omeri on 8/7/2026.
//

import SwiftUI

struct SubjectEditorPager: View {
	@Binding var draftSubjects: [EditableSubject]
	@Binding var editorPage: Int

	let pendingPrefillSlot: EditableSlot?
	let isSaving: Bool

	let dayLabel: (Int) -> String
	let allowedPeriods: (Int) -> [Int]
	let canUse: (Int, Int) -> Bool

	let addNewSubject: () -> Void
	let deleteSubject: (Int) -> Void
	let beginRenamingSubject: (Int) -> Void
	let selectSymbol: (EditableSubject.ID) -> Void

	var body: some View {
		TabView(selection: $editorPage) {
			ForEach(Array(draftSubjects.enumerated()), id: \.element.id) { index, draftSubject in
				Tab(draftSubject.name, systemImage: draftSubject.symbol, value: index) {
					if draftSubjects.indices.contains(index) {
						SubjectEditorPageView(
							subject: $draftSubjects[index],
							index: index,
							isSaving: isSaving,
							dayLabel: dayLabel,
							allowedPeriods: allowedPeriods,
							canUse: canUse,
							deleteSubject: deleteSubject,
							beginRenamingSubject: beginRenamingSubject,
							selectSymbol: selectSymbol
						)
					}
				}
			}

			Tab("Add Subject", systemImage: "plus", value: draftSubjects.count) {
				AddSubjectPageView(
					pendingPrefillSlot: pendingPrefillSlot,
					isSaving: isSaving,
					dayLabel: dayLabel,
					addNewSubject: addNewSubject
				)
			}
		}
		#if os(iOS)
		.tabViewStyle(.page(indexDisplayMode: .always))
		#else
		.tabViewStyle(.sidebarAdaptable)
		#endif
		.animation(.snappy, value: draftSubjects.count)
	}
}
