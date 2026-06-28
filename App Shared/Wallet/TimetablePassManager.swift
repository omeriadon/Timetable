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

	init() {
		// Only load if PassKit is actually available on this device platform (e.g., Mac vs iOS)
		if PKPassLibrary.isPassLibraryAvailable() {
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(passLibraryDidChange),
				name: NSNotification.Name(rawValue: PKPassLibraryNotificationName.PKPassLibraryDidChange.rawValue),
				object: nil
			)
			refreshPasses()
		}
	}

	@objc private func passLibraryDidChange(_: Notification) {
		Print("passLibraryDidChange")
		refreshPasses()
	}

	/// Scans Apple Wallet on a background thread and updates the cached list
	func refreshPasses() {
		Print("refreshing")
		guard PKPassLibrary.isPassLibraryAvailable() else { return }
		isLoading = true

		Task(priority: .userInitiated) {
			let allPasses = self.passLibrary.passes()
			Print("Found \(allPasses.count) raw passes in Wallet.")

			let extractedTimetables = allPasses.compactMap { $0.toReceivedTimetable() }

			await MainActor.run {
				withAnimation(.easeInOut) {
					self.receivedTimetables = extractedTimetables
					self.isLoading = false
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
