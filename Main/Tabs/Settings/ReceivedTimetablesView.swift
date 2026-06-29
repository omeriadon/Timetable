//
//   ReceivedTimetablesView.swift
//   Main
//
//   Created by Adon Omeri on 22/6/2026.
//

import SwiftUI

struct ReceivedTimetablesView: View {
	@Environment(\.dismiss) var dismiss

	@Environment(\.passManager) private var passManager
	private var receivedTimetables: Binding<ReceivedTimetables> {
		Binding(
			get: { passManager.receivedTimetables },
			set: { newValue in
				// Process the differences between the old array and the new array
				let oldValues = passManager.receivedTimetables

				// Example 1: Handle deletions if an item was removed from the list
				for oldItem in oldValues where !newValue.contains(where: { $0.id == oldItem.id }) {
					passManager.deletePass(for: oldItem)
				}

				// Example 2: Handle updates if an existing item's properties changed
				for newItem in newValue {
					if let oldItem = oldValues.first(where: { $0.id == newItem.id }), oldItem != newItem {
						passManager.updatePass(for: newItem, with: newItem.subjects)
					}
				}
			}
		)
	}

	@State private var renameItem: RenameTimetable?
	@State private var renameText: String = ""

	@State private var timetableToDelete: ReceivedTimetable?
	@State private var showDeleteConfirmation = false

	var body: some View {
		NavigationStack {
			List {
				ForEach(receivedTimetables.wrappedValue) { timetable in
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
					.swipeActions(edge: .trailing, allowsFullSwipe: false) {
						contextMenuButtons(for: timetable)
					}
				}
			}
			.alert("Rename Timetable", item: $renameItem) { item in
				TextField("Rename this timetable...", text: $renameText)

				Button("Save", role: .confirm) {
					let displayName = renameText
					Task {
						try await ReceivedTimetableSyncService.shared.setReceivedNameOverride(
							serialNumber: item.timetable.id,
							displayName: displayName
						)
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
					receivedTimetables.wrappedValue.removeAll { $0.id == timetable.id }
				}
			} message: { timetable in
				Text("Are you sure you want to delete \(timetable.sender)'s timetable?")
			}
		}
	}

	@ContentBuilder
	func contextMenuButtons(for timetable: ReceivedTimetable) -> some View {
		Button(role: .destructive) {
			let timetable = receivedTimetables.wrappedValue.first { $0.id == timetable.id }
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
