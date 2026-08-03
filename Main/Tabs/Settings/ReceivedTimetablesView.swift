import Defaults
import SwiftUI
import UniformTypeIdentifiers

struct ReceivedTimetablesView: View {
	@Default(.receivedTimetables) private var receivedTimetables
	@State private var timetableToDelete: ReceivedTimetable?
	@State private var showDeleteConfirmation = false
	@State private var exportDocument: TimetableShareDocument?
	@State private var showsFileExporter = false
	@State private var showsFileImporter = false
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
			.fileExporter(
				isPresented: $showsFileExporter,
				document: exportDocument,
				contentType: .timetableShare,
				defaultFilename: "Shared Timetable"
			) { result in
				if case let .failure(error) = result {
					badges.present(error: error, title: "Unable to export timetable")
				}
			}
			.fileImporter(
				isPresented: $showsFileImporter,
				allowedContentTypes: [.timetableShare]
			) { result in
				switch result {
					case let .success(url):
						importTimetableDocument(from: url)
					case let .failure(error):
						badges.present(error: error, title: "Unable to import timetable")
				}
			}
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button {
						showsFileImporter = true
					} label: {
						Label("Import Timetable File", systemImage: "square.and.arrow.down")
					}
				}
			}
		}
	}

	@ViewBuilder
	private func actions(for timetable: ReceivedTimetable) -> some View {
		if let id = UUID(uuidString: timetable.id),
		   let url = URL(string: "https://timetable.adonis.pt/share/\(id.uuidString)")
		{
			ShareLink(item: url) {
				Label("Share Link", systemImage: "square.and.arrow.up")
			}
		}
		Button("Export File", systemImage: "square.and.arrow.up") {
			exportDocument = TimetableShareDocument(locator: timetable.id)
			showsFileExporter = true
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

	private func importTimetableDocument(from url: URL) {
		let isSecurityScoped = url.startAccessingSecurityScopedResource()
		defer {
			if isSecurityScoped {
				url.stopAccessingSecurityScopedResource()
			}
		}

		do {
			let document = try TimetableShareDocument.read(from: url)
			Task {
				do {
					_ = try await ReceivedTimetableSyncService.shared.importTimetable(locator: document.locator)
					badges.addBadge(
						id: UUID(),
						title: "Imported shared timetable",
						priority: 3,
						view: .success
					)
				} catch {
					badges.present(error: error, title: "Unable to import timetable")
				}
			}
		} catch {
			badges.present(error: error, title: "Invalid timetable file")
		}
	}
}
