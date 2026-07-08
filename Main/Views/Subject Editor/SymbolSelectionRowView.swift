//
//  SymbolSelectionRowView.swift
//  Timetable
//
//  Created by Adon Omeri on 8/7/2026.
//

import SwiftUI

struct SymbolSelectionRowView: View {
	let subject: EditableSubject
	let isSaving: Bool
	let selectSymbol: (EditableSubject.ID) -> Void

	var body: some View {
		Button {
			selectSymbol(subject.id)
		} label: {
			HStack {
				Image(systemName: subject.symbol)
					.font(.title2)
					.frame(height: 15)

				Spacer()

				Text("Select Symbol")
					.padding(.trailing, 4)
			}
			.padding(10)
			.foregroundStyle(.white)
			.glassEffect(.clear.interactive(), in: Capsule())
			.frame(height: 25)
			.contentShape(.capsule)
		}
		.buttonStyle(.plain)
		.frame(height: 25)
		.disabled(isSaving)
	}
}
