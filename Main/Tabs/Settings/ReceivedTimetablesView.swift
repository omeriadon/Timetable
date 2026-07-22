import Defaults
import SwiftUI
#if os(iOS)
	import UIKit
#endif

struct ReceivedTimetablesView: View {
	@Default(.receivedTimetables) private var receivedTimetables
	@State private var timetableToDelete: ReceivedTimetable?
	@State private var showDeleteConfirmation = false
	@State private var shareURL: ShareableTimetableURL?
	@Environment(\.statusBadgeManager) private var badges
	@State private var networkManager = NetworkManager.shared

	var body: some View {
		NavigationStack {
			List {
				ForEach(receivedTimetables) { timetable in
					HStack {
						Text(timetable.sender).font(.title2)
						Spacer()
						Text("Received: \(timetable.receivedAt.formatted(date: .abbreviated, time: .omitted))")
							.font(.caption2)
							.foregroundStyle(.secondary)
					}
					.contextMenu { actions(for: timetable) }
					.swipeActions(edge: .trailing, allowsFullSwipe: false) { actions(for: timetable) }
				}
			}
			.disabled(!networkManager.isOnline)
			.overlay {
				if !networkManager.isOnline {
					ContentUnavailableView("Offline", systemImage: "wifi.slash", description: Text("Received timetable changes are unavailable until the connection returns."))
				}
			}
			.alert("Delete Timetable?", isPresented: $showDeleteConfirmation, presenting: timetableToDelete) { timetable in
				Button("Cancel", role: .cancel) {}
				Button("Delete", role: .destructive) { delete(timetable) }
			} message: { timetable in
				Text("Delete \(timetable.sender)'s timetable from every signed-in device?")
			}
			#if os(iOS)
			.sheet(item: $shareURL) { ShareSheet(items: [$0.url]) }
			#endif
		}
	}

	@ViewBuilder
	private func actions(for timetable: ReceivedTimetable) -> some View {
		if let id = UUID(uuidString: timetable.id),
		   let url = URL(string: "https://timetable.adonis.pt/share/\(id.uuidString)")
		{
			Button("Share Link", systemImage: "square.and.arrow.up") {
				shareURL = ShareableTimetableURL(url: url)
			}
		}
		Button("Delete", systemImage: "trash", role: .destructive) {
			timetableToDelete = timetable
			showDeleteConfirmation = true
		}
	}

	private func delete(_ timetable: ReceivedTimetable) {
		Task {
			do {
				try await ReceivedTimetableSyncService.shared.deleteReceivedTimetable(serialNumber: timetable.id)
			} catch {
				badges.present(error: error, title: "Unable to delete timetable")
			}
		}
	}
}

private struct ShareableTimetableURL: Identifiable {
	let id = UUID()
	let url: URL
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
