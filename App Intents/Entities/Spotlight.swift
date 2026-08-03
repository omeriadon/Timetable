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
			let received = Defaults[.receivedTimetables].filter { !$0.isDeleted }
			var timetables = received.toTimetableEntities()
			if !Defaults[.timetable].isEmpty {
				timetables.append(TimetableEntity(id: "timetable.owner", subjects: Defaults[.timetable].toSubjectEntities(prefix: "subject.owner")))
			}
			try Task.checkCancellation()
			let uniqueTimetables = Dictionary(timetables.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }).values.sorted { $0.id < $1.id }
			let uniqueSubjects = Dictionary(uniqueTimetables.flatMap(\.subjects).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }).values.sorted { $0.id < $1.id }
			try Task.checkCancellation()
			try await removeAll()
			try Task.checkCancellation()
			try await timetableIndex.indexAppEntities(Array(uniqueTimetables))
			try await subjectIndex.indexAppEntities(Array(uniqueSubjects))
			TimetableShortcuts.updateAppShortcutParameters()
		} catch is CancellationError {
			return
		} catch {
			PrintError("Spotlight indexing failed", category: .spotlight, error: error)
		}
	}

	func removeAll() async throws {
		try await timetableIndex.deleteAllSearchableItems()
		try await subjectIndex.deleteAllSearchableItems()
	}
}

func indexEntities() async {
	await SpotlightIndexer.shared.rebuildFromDefaults()
}
