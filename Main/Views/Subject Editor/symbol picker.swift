//
//  symbol picker.swift
//  Timetable
//
//  Created by Adon Omeri on 8/7/2026.
//

import SFSymbolsPicker
import SwiftUI

struct SymbolPickerSheet: View {
	let subjectID: EditableSubject.ID

	@Binding var draftSubjects: [EditableSubject]

	var body: some View {
		SymbolsPicker(
			selection: selectedSymbolBinding,
			title: "",
			searchLabel: "Search symbols...",
			autoDismiss: true
		)
	}

	private var selectedSymbolBinding: Binding<String> {
		Binding(
			get: {
				draftSubjects.first(where: { $0.id == subjectID })?.symbol ?? "questionmark"
			},
			set: { newValue in
				guard let index = draftSubjects.firstIndex(where: { $0.id == subjectID }) else { return }
				draftSubjects[index].symbol = newValue
			}
		)
	}
}
