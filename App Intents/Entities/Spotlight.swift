//
//   Spotlight.swift
//   App Intents
//
//   Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import CoreSpotlight
import Defaults

@MainActor
final class SpotlightIndexer {
	static let shared = SpotlightIndexer()
	private let timetableIndex = CSSearchableIndex(name: "Timetables")
	private let subjectIndex = CSSearchableIndex(name: "Subjects")
	private var rebuildTask: Task<Void, Never>?

	func rebuildFromDefaults() async {
		rebuildTask?.cancel()
		rebuildTask = Task { @MainActor in
			try? await Task.sleep(for: .milliseconds(150))
			guard !Task.isCancelled else { return }
			await performRebuild()
		}
		await rebuildTask?.value
	}

	func indexOwnerTimetable() async {
		await rebuildFromDefaults()
	}

	func indexReceivedTimetables() async {
		await rebuildFromDefaults()
	}

	func removeDeletedTimetables() async {
		await rebuildFromDefaults()
	}

	private func performRebuild() async {
		do {
			try await removeAll()
			var timetables = Defaults[.receivedTimetables]
				.filter { !$0.isDeleted && !Defaults[.receivedTombstoneIDs].contains($0.id) }
				.toTimetableEntities()
			timetables.append(TimetableEntity(id: "timetable.owner", subjects: Defaults[.timetable].toSubjectEntities(prefix: "subject.owner")))
			try await timetableIndex.indexAppEntities(timetables)
			try await subjectIndex.indexAppEntities(timetables.flatMap(\.subjects))
		} catch {
			PrintError("Spotlight indexing failed", category: .spotlight, error: error)
		}
	}

	func removeAll() async throws {
		try await timetableIndex.deleteAllSearchableItems()
		try await subjectIndex.deleteAllSearchableItems()
	}
}

enum TimetableDeepLink: Equatable {
	case timetable(id: String?)
	case subject(timetableID: String?, subjectID: String, slot: Slot?)

	init?(url: URL) {
		guard url.scheme == "timetable" else { return nil }
		let parts = ([url.host].compactMap(\.self) + url.pathComponents.dropFirst().filter { $0 != "/" })
		guard let first = parts.first else { self = .timetable(id: nil); return }
		if first == "received", parts.count >= 2 {
			let id = String(parts[1])
			if parts.count >= 4, parts[2] == "subject" {
				self = .subject(timetableID: id, subjectID: String(parts[3]), slot: Self.slot(from: url))
			} else {
				self = .timetable(id: id)
			}
			return
		}
		self = .timetable(id: first == "owner" ? nil : first)
	}

	private static func slot(from url: URL) -> Slot? {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
		      let query = components.queryItems,
		      let day = query.first(where: { $0.name == "day" })?.value.flatMap(Int.init),
		      let session = query.first(where: { $0.name == "session" })?.value.flatMap(Int.init)
		else { return nil }
		return Slot(day, session)
	}
}

func indexEntities() async {
	await SpotlightIndexer.shared.rebuildFromDefaults()
}
