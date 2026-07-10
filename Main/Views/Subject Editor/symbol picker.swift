//
//  symbol picker.swift
//  Timetable
//
//  Created by Adon Omeri on 8/7/2026.
//

import SwiftUI
#if os(iOS)
	import SFSymbolsPicker
#endif

struct SymbolPickerSheet: View {
	let subjectID: EditableSubject.ID

	@Binding var draftSubjects: [EditableSubject]

	var body: some View {
		#if os(iOS)
			SymbolsPicker(
				selection: selectedSymbolBinding,
				title: "",
				searchLabel: "Search symbols...",
				autoDismiss: true
			)
		#else
			Form {
				TextField("SF Symbol name", text: selectedSymbolBinding)
				Label("Preview", systemImage: selectedSymbolBinding.wrappedValue)
			}
			.padding()
		#endif
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
