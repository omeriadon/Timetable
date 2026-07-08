//
//  SubjectHeaderRowView.swift
//  Timetable
//
//  Created by Adon Omeri on 8/7/2026.
//

import SwiftUI

struct SubjectHeaderRowView: View {
	@Binding var subject: EditableSubject

	let index: Int
	let isSaving: Bool
	let deleteSubject: (Int) -> Void
	let beginRenamingSubject: (Int) -> Void

	var body: some View {
		GlassEffectContainer(spacing: 0) {
			HStack(alignment: .center) {
				Button {
					beginRenamingSubject(index)
				} label: {
					HStack(spacing: 0) {
						Text(subject.name.isEmpty ? "Subject Name" : subject.name)
							.font(.title)
							.padding(10)
							.padding(.leading, 8)
							.contentTransition(.numericText())
							.lineLimit(1)

						Spacer(minLength: 0)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.contentShape(Capsule())
				}
				.buttonStyle(.plain)
				.disabled(isSaving)
				.background {
					Capsule()
						.fill(subject.color.opacity(0.22))
						.animation(.snappy(duration: 0.25), value: subject.color)
				}
				.glassEffect(
					.clear.tint(subject.color).interactive(),
					in: Capsule()
				)
				.animation(.snappy(duration: 0.25), value: closestColor(to: subject.color))

				Button(role: .destructive) {
					withAnimation {
						deleteSubject(index)
					}
				} label: {
					Label("Delete Subject", systemImage: "trash")
						.font(.title3)
						.padding(10)
						.labelStyle(.iconOnly)
				}
				.buttonStyle(.plain)
				.buttonBorderShape(.circle)
				.glassEffect(.clear.tint(.red).interactive(), in: Circle())
				.disabled(isSaving)
			}
			.padding(.top, 10)
		}
	}
}
