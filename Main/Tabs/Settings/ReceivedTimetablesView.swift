//
//   ReceivedTimetablesView.swift
//   Main
//
//   Created by Adon Omeri on 22/6/2026.
//

import SwiftUI
#if os(iOS)
	import UIKit
#endif

private struct ShareablePassFile: Identifiable {
	let id = UUID()
	let url: URL
}

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
	@State private var shareFile: ShareablePassFile?
	@Environment(\.statusBadgeManager) private var badges
	@State private var networkManager = NetworkManager.shared

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
				Section {
					EmptyView()
				} footer: {
					Text("Reorder timetables to put your highest-priority timetable first. Widgets and timetable comparisons use this order.")
				}
			}
			.disabled(!networkManager.isOnline)
			.overlay {
				if !networkManager.isOnline {
					ContentUnavailableView("Offline", systemImage: "wifi.slash", description: Text("Received timetable changes are unavailable until a connection is restored."))
				}
			}
			.alert("Rename Timetable", item: $renameItem) { item in
				TextField("Rename this timetable...", text: $renameText)

				Button("Save", role: .confirm) {
					let displayName = renameText
					Task {
						do {
							try await ReceivedTimetableSyncService.shared.setReceivedNameOverride(
								serialNumber: item.timetable.id,
								displayName: displayName
							)
						} catch {
							badges.present(error: error, title: "Unable to rename timetable")
						}
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
					Task {
						do {
							try await ReceivedTimetableSyncService.shared.deleteReceivedTimetable(serialNumber: timetable.id)
							passManager.deletePass(for: timetable)
						} catch { badges.present(error: error, title: "Unable to delete timetable") }
					}
				}
			} message: { timetable in
				Text("Are you sure you want to delete \(timetable.sender)'s timetable?")
			}
			#if os(iOS)
			.sheet(item: $shareFile) { ShareSheet(items: [$0.url]) }
			#endif
		}
	}

	@ContentBuilder
	func contextMenuButtons(for timetable: ReceivedTimetable) -> some View {
		if timetable.isShareable {
			Button {
				Task { await share(timetable) }
			} label: {
				Label("Share Pass", systemImage: "square.and.arrow.up")
			}
		}

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

	private func share(_ timetable: ReceivedTimetable) async {
		do {
			shareFile = try await ShareablePassFile(url: WalletPassService.shared.receivedPassFileURL(serialNumber: timetable.id))
		} catch {
			try? await ReceivedTimetableSyncService.shared.downloadProjectionAndOverrides()
			badges.addBadge(id: UUID(), title: "Unable to share timetable", secondaryText: error.localizedDescription, priority: 4, view: .error)
		}
	}
}

#if os(iOS)
	private struct ShareSheet: UIViewControllerRepresentable {
		let items: [Any]

		func makeUIViewController(context _: Context) -> UIActivityViewController {
			UIActivityViewController(activityItems: items, applicationActivities: nil)
		}

		func updateUIViewController(_: UIActivityViewController, context _: Context) {}
	}
#endif

#Preview {
	ReceivedTimetablesView()
}
