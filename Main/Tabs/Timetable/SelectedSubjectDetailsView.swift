//
//   SelectedSubjectDetailsView.swift
//   Main
//

import SwiftUI

struct SelectedSubjectDetailsView: View {
	let subject: Subject

	var body: some View {
		HStack {
			Label(subject.classroom.displayName, systemImage: "door.left.hand.open")
			Spacer()
			Label(subject.teacher.displayName, systemImage: "person.fill")
		}
		.padding(15)
		.glassEffect(.clear.tint(subject.colour.swiftUIColor).interactive(), in: Capsule())
	}
}
