//
//  SubjectContextPopover.swift
//  Timetable
//
//  Created by Adon Omeri on 5/7/2026.
//

import SwiftUI

struct SubjectContextPopover: View {
	let owner: String
	let subject: Subject

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			header

			VStack(spacing: 10) {
				infoRow(
					title: "Room",
					value: classroomText,
					systemImage: "door.left.hand.open"
				)

				infoRow(
					title: "Teacher",
					value: Text(subject.teacher.displayName),
					systemImage: "person.fill"
				)
			}
		}
		.frame(width: 290)
		.padding(15)
		.presentationCornerRadius(5)
		.presentationBackground(subject.colour.swiftUIColor.opacity(0.5))
	}

	private var header: some View {
		HStack(spacing: 12) {
			Image(systemName: subject.symbol)
				.font(.largeTitle)
				.bold()
				.padding(.trailing, 3)

			VStack(alignment: .leading, spacing: 3) {
				Text(owner)
					.font(.title3)
					.foregroundStyle(.secondary)
					.lineLimit(1)

				Text(subject.id)
					.font(.title2)
					.lineLimit(1)
					.bold()
			}

			Spacer()
		}
		.padding(.bottom, 3)
	}

	private func infoRow(title: String, value: some View, systemImage: String) -> some View {
		HStack(spacing: 12) {
			Image(systemName: systemImage)
				.font(.title)
				.padding(.leading, 7)
				.frame(width: 25)
				.bold()

			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.foregroundStyle(.secondary)

				value
					.font(.title3)
					.foregroundStyle(.primary)
					.lineLimit(2)
					.bold()
			}

			Spacer()
		}
		.padding(6)
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 15))
	}

	@ContentBuilder
	private var classroomText: some View {
		switch subject.classroom {
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
				Text(rawLocation)
		}
	}
}
