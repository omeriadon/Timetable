//
//  SubjectMetadataEditorView.swift
//  Timetable
//
//  Created by Adon Omeri on 8/7/2026.
//

import SwiftUI

struct SubjectMetadataEditorView: View {
	@Binding var subject: EditableSubject

	var body: some View {
		VStack(spacing: 10) {
			TextField("Classroom code", text: $subject.classroom)
				.textInputAutocapitalization(.characters)

			TextField("Teacher surname", text: $subject.teacher)
				.textInputAutocapitalization(.words)
		}
		.textFieldStyle(.roundedBorder)
	}
}
