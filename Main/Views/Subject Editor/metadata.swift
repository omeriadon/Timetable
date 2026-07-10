//
//  metadata.swift
//  Timetable
//
//  Created by Adon Omeri on 8/7/2026.
//

import SwiftUI

struct SubjectMetadataEditorView: View {
	@Binding var subject: EditableSubject

	@State private var editingTarget: MetadataEditTarget?
	@State private var draftValue = ""

	private var parsedClassroom: Classroom {
		Classroom(rawLocation: subject.classroom)
	}

	private var parsedTeacher: Teacher {
		Teacher(rawNotes: subject.teacher)
	}

	var body: some View {
		VStack(spacing: 10) {
			Button {
				draftValue = subject.classroom
				editingTarget = .classroom
			} label: {
				HStack {
					switch parsedClassroom {
						case let .room(building, floor, number):
							let secondaryText = if let floor {
								"\(floor.displayName) \(building.displayName)"
							} else {
								building.displayName
							}

							HStack(spacing: 10) {
								Text(secondaryText)
									.foregroundStyle(.secondary)

								Text(number.description)
									.font(.headline)
									.bold()
							}
						case let .unknown(rawLocation):
							Text("Classroom: \(rawLocation)")
								.font(.headline)
					}
				}
			}
			.buttonStyle(.plain)

			Button {} label: {
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
			.background {
				Capsule()
					.fill(subject.color.opacity(0.22))
					.animation(.snappy(duration: 0.25), value: subject.color)
			}
			.glassEffect(
				.clear.tint(subject.color).interactive(),
				in: Capsule()
			)

			Button {
				draftValue = subject.teacher
				editingTarget = .teacher
			} label: {
				metadataRow(
					title: "Teacher",
					value: parsedTeacher.displayName,
					placeholder: "No teacher",
					systemImage: "person.text.rectangle"
				)
			}
			.buttonStyle(.plain)
		}
		.alert("Edit \(editingTarget?.title ?? "Metadata")", item: $editingTarget) { target in
			TextField(target.placeholder, text: $draftValue)

			Button("Save") {
				commit(target)
			}

			Button("Cancel", role: .cancel) {}
		} message: { target in
			Text(target.helpText)
		}
	}

	private func commit(_ target: MetadataEditTarget) {
		let cleaned = draftValue.trimmingCharacters(in: .whitespacesAndNewlines)

		switch target {
			case .classroom:
				subject.classroom = cleaned

			case .teacher:
				subject.teacher = cleaned
		}
	}

	private func metadataRow(
		title: String,
		value: String,
		placeholder: String,
		systemImage: String
	) -> some View {
		HStack(spacing: 12) {
			Image(systemName: systemImage)
				.foregroundStyle(.secondary)
				.frame(width: 24)

			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.caption)
					.foregroundStyle(.secondary)

				Text(value.isEmpty ? placeholder : value)
					.font(.headline)
					.foregroundStyle(value.isEmpty ? .secondary : .primary)
					.lineLimit(1)
			}

			Spacer(minLength: 0)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 10)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
	}
}

private enum MetadataEditTarget: Identifiable {
	case classroom
	case teacher

	var id: Self {
		self
	}

	var title: String {
		switch self {
			case .classroom: "Classroom"
			case .teacher: "Teacher"
		}
	}

	var placeholder: String {
		switch self {
			case .classroom: "MU12"
			case .teacher: "Attending Staff : JSMITH"
		}
	}

	var helpText: String {
		switch self {
			case .classroom:
				"Use the raw room code."

			case .teacher:
				"Use the raw teacher note."
		}
	}
}
