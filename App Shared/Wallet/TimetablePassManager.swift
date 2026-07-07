//
//   TimetablePassManager.swift
//   App Shared
//
//   Created by Adon Omeri on 23/6/2026.
//

import Defaults
import Foundation
import PassKit
import SwiftUI

@Observable
final class TimetablePassManager {
	// Cached array to prevent constant re-computation across views
	private(set) var receivedTimetables: ReceivedTimetables = []
	private(set) var isLoading = false

	private let passLibrary = PKPassLibrary()
	private var projectionUploadHandler: (() async throws -> Void)?

	init() {
		// Only load if PassKit is actually available on this device platform (e.g., Mac vs iOS)
		if PKPassLibrary.isPassLibraryAvailable() {
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(passLibraryDidChange),
				name: NSNotification.Name(rawValue: PKPassLibraryNotificationName.PKPassLibraryDidChange.rawValue),
				object: nil
			)
			refreshPasses(uploadProjection: false)
		}
	}

	func configureProjectionUpload(_ upload: @escaping () async throws -> Void) {
		projectionUploadHandler = upload
	}

	@objc private func passLibraryDidChange(_: Notification) {
		Print("passLibraryDidChange")
		refreshPasses()
	}

	/// Scans Apple Wallet on a background thread and updates the cached list
	func refreshPasses(uploadProjection: Bool = true) {
		Print("refreshing")
		guard PKPassLibrary.isPassLibraryAvailable() else { return }
		isLoading = true

		Task(priority: .userInitiated) {
			let allPasses = self.passLibrary.passes()
			Print("Found \(allPasses.count) raw passes in Wallet.")

			var extractedTimetables: [ReceivedTimetable] = []
			for pass in allPasses {
				guard let timetable = pass.toReceivedTimetable() else { continue }
				if timetable.isDeleted || Defaults[.receivedTombstoneIDs].contains(timetable.id) {
					self.passLibrary.removePass(pass)
					continue
				}
				extractedTimetables.append(timetable)
			}

			await MainActor.run {
				withAnimation(.easeInOut) {
					var merged = Dictionary(uniqueKeysWithValues: Defaults[.receivedTimetables].map { ($0.id, $0) })
					for observed in extractedTimetables {
						if let current = merged[observed.id], current.contentRevision > observed.contentRevision { continue }
						merged[observed.id] = observed
					}
					let active = merged.values.filter { !Defaults[.receivedTombstoneIDs].contains($0.id) }.sorted { $0.receivedAt < $1.receivedAt }
					self.receivedTimetables = active
					Defaults[.receivedTimetables] = active
					Defaults[.installedWalletTimetableIDs] = Set(extractedTimetables.map(\.id))
					Defaults[.walletRevision] += 1
					self.isLoading = false
				}
			}

			if uploadProjection, let projectionUploadHandler {
				do {
					try await projectionUploadHandler()
				} catch NetworkError.offline {
					return
				} catch {
					PrintError("Failed to upload Wallet projection", category: .wallet, error: error)
				}
			}
		}
	}

	/// Completely deletes a pass from the user's Apple Wallet matching a timetable instance
	func deletePass(for timetable: ReceivedTimetable) {
		Print("deletePass")
		guard PKPassLibrary.isPassLibraryAvailable() else { return }

		// Find the native pass in the system matchable by its identification characteristics
		let systemPasses = passLibrary.passes()

		// ✨ THE FIX: Match based on stable values (sender + timestamp) instead of the volatile random UUID
		let matchingPass = systemPasses.first { pass in
			guard let extracted = pass.toReceivedTimetable() else { return false }
			return extracted.sender == timetable.sender && extracted.receivedAt == timetable.receivedAt
		}

		if let matchingPass {
			passLibrary.removePass(matchingPass)
			// Note: The PKPassLibraryDidChange notification will automatically trigger refreshPasses()
			Print("pass found and removed!")
		} else {
			PrintError("pass not found")
		}
	}

	/// Handles requests to replace old system metadata safely
	func updatePass(for timetable: ReceivedTimetable, with _: [Subject]) {
		// To natively update a pass template, you usually deploy an updated cryptographic .pkpass file
		// package back into the library, or update via push notifications if connected to a web service.
		// For localized updates, regenerate your pass with new info and re-add it using `PKPassLibrary.replacePass(with:)`
		PrintError("Update pass triggered for \(timetable.sender). Regenerate and call replacePass(with:)")
	}
}

extension EnvironmentValues {
	private static let defaultPassManager = TimetablePassManager()

	@Entry var passManager: TimetablePassManager = Self.defaultPassManager
}
