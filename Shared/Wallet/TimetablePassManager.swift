//
//  TimetablePassManager.swift
//  Timetable
//
//  Created by Adon Omeri on 22/6/2026.
//

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
    
	@objc private func passLibraryDidChange(_ notification: Notification) {
		refreshPasses()
	}
    
	/// Scans Apple Wallet on a background thread and updates the cached list
	func refreshPasses() {
		print("refreshing")
		guard PKPassLibrary.isPassLibraryAvailable() else { return }
		isLoading = true
        
		Task(priority: .userInitiated) {
			// Fetch raw passes from Apple Wallet
			let allPasses = self.passLibrary.passes()
			print(allPasses)

			// Map and safely extract your Custom models
			let extractedTimetables = allPasses.compactMap { $0.toReceivedTimetable() }
			print(extractedTimetables)

			await MainActor.run {
				withAnimation(.easeInOut) {
					self.receivedTimetables = extractedTimetables
					self.isLoading = false
				}
			}
			print("done")
		}
	}
    
	/// Completely deletes a pass from the user's Apple Wallet matching a timetable instance
	func deletePass(for timetable: ReceivedTimetable) {
		guard PKPassLibrary.isPassLibraryAvailable() else { return }
        
		// Find the native pass in the system matchable by its identification characteristics
		let systemPasses = passLibrary.passes()
		if let matchingPass = systemPasses.first(where: { $0.toReceivedTimetable()?.id == timetable.id }) {
			passLibrary.removePass(matchingPass)
			// Note: The PKPassLibraryDidChange notification will automatically trigger refreshPasses()
		}
	}
    
	/// Handles requests to replace old system metadata safely
	func updatePass(for timetable: ReceivedTimetable, with updatedSubjects: [Subject]) {
		// To natively update a pass template, you usually deploy an updated cryptographic .pkpass file
		// package back into the library, or update via push notifications if connected to a web service.
		// For localized updates, regenerate your pass with new info and re-add it using `PKPassLibrary.replacePass(with:)`
		print("Update pass triggered for \(timetable.sender). Regenerate and call replacePass(with:)")
	}
}

// MARK: - Environment Value Injection Support

extension EnvironmentValues {
	@Entry var passManager: TimetablePassManager = .init()
}
