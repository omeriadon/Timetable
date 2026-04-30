//
//  PMS_TimetableApp.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import Foundation
import Defaults
import SwiftUI

struct ImportResult: Equatable {
	let success: Bool
	let message: String
}

@main
struct PMS_TimetableApp: App {
	@State private var importedFileURL: URL?
	@State private var importStatus: ImportResult?
	@State private var receivedTimetableData: ShareableTimetableData?

	var body: some Scene {
		WindowGroup {
			ContentView()
				.preferredColorScheme(.dark)
				.onOpenURL { url in
					handleDeepLink(url)
				}
				.environment(\.importedFileURL, $importedFileURL)
				.environment(\.importStatus, $importStatus)
				.environment(\.receivedTimetableData, $receivedTimetableData)
		}
	}

	private func handleDeepLink(_ url: URL) {
		guard url.scheme == "pmstimetable" else { return }
		
		let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
		guard let queryItems = components?.queryItems,
			  let dataParam = queryItems.first(where: { $0.name == "data" })?.value else {
			return
		}
		
		do {
			let timetableData = try ShareableTimetableData.fromBase64URL(dataParam)
			receivedTimetableData = timetableData
			saveReceivedTimetable(timetableData)
		} catch {
			print("Failed to decode timetable data: \(error)")
		}
	}

	private func saveReceivedTimetable(_ data: ShareableTimetableData) {
		let classes = data.classes.map { shareableClass in
			Class(
				id: shareableClass.name,
				symbol: shareableClass.symbol,
				colour: RGBAColor(hexString: shareableClass.color),
				slots: shareableClass.slots.map { Slot($0.day, $0.period) }
			)
		}

		let receivedTimetable = ReceivedTimetable(
			sender: data.sender,
			classes: classes,
			receivedAt: Date()
		)

		var existing = Defaults[.receivedTimetables]
		existing.removeAll { $0.sender == data.sender }
		existing.append(receivedTimetable)
		Defaults[.receivedTimetables] = existing
	}
}

struct ImportedFileURLKey: EnvironmentKey {
	static let defaultValue: Binding<URL?> = .constant(nil)
}

struct ImportStatusKey: EnvironmentKey {
	static let defaultValue: Binding<ImportResult?> = .constant(nil)
}

struct ReceivedTimetableDataKey: EnvironmentKey {
	static let defaultValue: Binding<ShareableTimetableData?> = .constant(nil)
}

extension EnvironmentValues {
	var importedFileURL: Binding<URL?> {
		get { self[ImportedFileURLKey.self] }
		set { self[ImportedFileURLKey.self] = newValue }
	}

	var importStatus: Binding<ImportResult?> {
		get { self[ImportStatusKey.self] }
		set { self[ImportStatusKey.self] = newValue }
	}
	
	var receivedTimetableData: Binding<ShareableTimetableData?> {
		get { self[ReceivedTimetableDataKey.self] }
		set { self[ReceivedTimetableDataKey.self] = newValue }
	}
}
