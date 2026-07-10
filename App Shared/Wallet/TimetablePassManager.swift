import Defaults
import Foundation
import Observation
import PassKit
import SwiftUI
import WidgetKit

struct WalletTimetableReader {
	private let library = PKPassLibrary()

	func timetablePasses() -> [PKPass] {
		library.passes()
	}

	func decode(_ pass: PKPass) -> ReceivedTimetable? {
		pass.toReceivedTimetable()
	}
}

@MainActor
@Observable
final class TimetablePassManager {
	private(set) var receivedTimetables: ReceivedTimetables = []
	private(set) var isLoading = false

	private let passLibrary = PKPassLibrary()
	private let reader = WalletTimetableReader()
	private var refreshTask: Task<Void, Never>?
	private var debounceTask: Task<Void, Never>?
	private var projectionUploadHandler: (() async throws -> Void)?

	init(loadImmediately: Bool = true) {
		guard PKPassLibrary.isPassLibraryAvailable() else { return }
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(passLibraryDidChange),
			name: NSNotification.Name(rawValue: PKPassLibraryNotificationName.PKPassLibraryDidChange.rawValue),
			object: nil
		)
		if loadImmediately { refreshPasses(uploadProjection: false) }
	}

	func configureProjectionUpload(_ upload: @escaping () async throws -> Void) {
		projectionUploadHandler = upload
	}

	@objc private func passLibraryDidChange(_: Notification) {
		refreshPasses()
	}

	func refreshPasses(uploadProjection: Bool = true) {
		guard PKPassLibrary.isPassLibraryAvailable() else { return }
		debounceTask?.cancel()
		debounceTask = Task { @MainActor in
			try? await Task.sleep(for: .milliseconds(150))
			guard !Task.isCancelled else { return }
			await reconcile(uploadProjection: uploadProjection)
		}
	}

	private func reconcile(uploadProjection: Bool) async {
		if let refreshTask { await refreshTask.value; return }
		isLoading = true
		let task = Task { @MainActor in
			var extracted: [ReceivedTimetable] = []
			for pass in reader.timetablePasses() {
				guard let timetable = reader.decode(pass) else { continue }
				if timetable.isDeleted || Defaults[.receivedTombstoneIDs].contains(timetable.id) {
					passLibrary.removePass(pass)
					continue
				}
				extracted.append(timetable)
			}
			extracted.sort { $0.receivedAt < $1.receivedAt }
			let changed = Defaults[.receivedTimetables] != extracted
			receivedTimetables = extracted
			Defaults[.receivedTimetables] = extracted
			Defaults[.installedWalletTimetableIDs] = Set(extracted.map(\.id))
			Defaults[.lastWalletReconciliation] = .now
			if changed { Defaults[.walletRevision] += 1 }
			if changed {
				WidgetCenter.shared.reloadAllTimelines()
			}
			if uploadProjection, let projectionUploadHandler {
				try? await projectionUploadHandler()
			}
			isLoading = false
		}
		refreshTask = task
		await task.value
		refreshTask = nil
	}

	func deletePass(for timetable: ReceivedTimetable) {
		guard PKPassLibrary.isPassLibraryAvailable() else { return }
		if let pass = passLibrary.passes().first(where: { reader.decode($0)?.id == timetable.id }) {
			passLibrary.removePass(pass)
		}
	}

	func updatePass(for timetable: ReceivedTimetable, with _: [Subject]) {
		PrintError("Update pass triggered for \(timetable.sender). Regenerate and call replacePass(with:)")
	}
}

extension EnvironmentValues {
	private static let defaultPassManager = TimetablePassManager(loadImmediately: false)
	@Entry var passManager: TimetablePassManager = Self.defaultPassManager
}
