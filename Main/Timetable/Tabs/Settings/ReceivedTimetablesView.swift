//
//  ReceivedTimetablesView.swift
//  Timetable
//
//  Created by Adon Omeri on 22/6/2026.
//

import Defaults
import SwiftUI

struct ReceivedTimetablesView: View {
	@Environment(\.dismiss) var dismiss

	@Default(.receivedTimetables) var receivedTimetables

	@State private var renameItem: RenameTimetable?
	@State private var renameText: String = ""

	@State private var timetableToDelete: ReceivedTimetable?
	@State private var showDeleteConfirmation = false

	var body: some View {
		NavigationStack {
			List {
				ForEach(receivedTimetables) { timetable in
					HStack {
						Text(timetable.sender)
							.font(.title2)

						Spacer()

						Text("Received: \(timetable.receivedAt.formatted(date: .abbreviated, time: .omitted))")
							.font(.caption2)
							.foregroundStyle(.secondary)
					}
					.contentShape(.rect)
					.contextMenu {
						contextMenuButtons(for: timetable)
					}
				}
			}
			.alert("Rename Timetable", item: $renameItem) { item in
				TextField("Rename this timetable...", text: $renameText)

				Button("Save", role: .confirm) {
					if let index = receivedTimetables.firstIndex(where: { $0.id == item.timetable.id }) {
						receivedTimetables[index].sender = renameText
					}

					renameItem = nil
					renameText = ""
				}
				.keyboardShortcut(.return)

				Button("Cancel", role: .cancel) {
					renameItem = nil
				}
				.keyboardShortcut(.escape)
			}
			.alert("Delete Timetable?", isPresented: $showDeleteConfirmation, presenting: timetableToDelete) { timetable in
				Button("Cancel", role: .cancel) {}
				Button("Delete", role: .destructive) {
					receivedTimetables.removeAll { $0.id == timetable.id }
				}
			} message: { timetable in
				Text("Are you sure you want to delete \(timetable.sender)'s timetable?")
			}
		}
	}

	@ContentBuilder
	func contextMenuButtons(for timetable: ReceivedTimetable) -> some View {
		Button(role: .destructive) {
			let timetable = receivedTimetables.first { $0.id == timetable.id }
			timetableToDelete = timetable
			showDeleteConfirmation = true
		} label: {
			Label("Delete", systemImage: "trash")
				.tint(.red)
		}

		Button {
			renameItem = RenameTimetable(
				id: timetable.id,
				timetable: timetable
			)
			renameText = timetable.sender
		} label: {
			Label("Rename", systemImage: "pencil")
		}
	}
}

#Preview {
	ReceivedTimetablesView()
}
