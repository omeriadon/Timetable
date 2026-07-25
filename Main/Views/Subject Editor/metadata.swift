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

							HStack(spacing: 5) {
								Image(systemName: "door.left.hand.open")
									.foregroundStyle(.secondary)

								Text("Classroom")
									.foregroundStyle(.secondary)

								Spacer()

								HStack(spacing: 10) {
									Text(secondaryText)
										.foregroundStyle(.secondary)

									Text(number.description)
										.font(.headline)
										.bold()
								}
								.font(.headline)
								.lineLimit(1)
							}
							.padding(.horizontal, 12)
							.padding(.vertical, 10)
							.frame(maxWidth: .infinity, alignment: .leading)
							.glassEffect(.clear, in: RoundedRectangle(cornerRadius: 20))

						case let .unknown(rawLocation):
							HStack(spacing: 5) {
								Image(systemName: "door.left.hand.open")
									.foregroundStyle(.secondary)

								Text("Classroom")
									.foregroundStyle(.secondary)

								Spacer()

								Text(rawLocation)
									.font(.headline)
									.lineLimit(1)
							}
							.padding(.horizontal, 12)
							.padding(.vertical, 10)
							.frame(maxWidth: .infinity, alignment: .leading)
							.glassEffect(.clear, in: RoundedRectangle(cornerRadius: 20))
					}
				}
			}
			.buttonStyle(.plain)

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
		HStack(spacing: 5) {
			Image(systemName: systemImage)
				.foregroundStyle(.secondary)

			Text(title)
				.foregroundStyle(.secondary)

			Spacer()

			Text(value.isEmpty ? placeholder : value)
				.font(.headline)
				.foregroundStyle(value.isEmpty ? .secondary : .primary)
				.lineLimit(1)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 10)
		.frame(maxWidth: .infinity, alignment: .leading)
		.glassEffect(.clear, in: RoundedRectangle(cornerRadius: 20))
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
