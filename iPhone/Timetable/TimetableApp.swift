//
//  TimetableApp.swift
//  Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import ActivityKit
import Foundation
import SwiftUI

func startPushToStartListener() {
	Task {
		for await token in Activity<iPhone_Widget_ExtensionAttributes>.pushToStartTokenUpdates {
			let tokenString = token.map { String(format: "%02x", $0) }.joined()

			print("PUSH-TO-START TOKEN (hex): \(tokenString)")
			let base64 = Data(token).base64EncodedString()
			print("BASE64: \(base64)")

			Task {
				await NetworkManager.shared.registerPushToStartToken(tokenString)
			}
		}
	}
}

struct ImportResult: Equatable {
	let success: Bool
	let message: String
}

@main
struct TimetableApp: App {
	@State private var importedFileURL: URL?
	@State private var importStatus: ImportResult?
	@State private var receivedTimetableData: ShareableTimetableData?

	init() {
		startPushToStartListener()
		#if DEBUG
		let _ = try? LiveActivityManager.shared.startTestActivity()
		#endif
	}

	var body: some Scene {
		WindowGroup {
			ContentView()
				.preferredColorScheme(.dark)
				.onOpenURL { url in
					handleIncomingURL(url)
				}
				.environment(\.importedFileURL, $importedFileURL)
				.environment(\.importStatus, $importStatus)
				.environment(\.receivedTimetableData, $receivedTimetableData)
		}
	}

	private func handleIncomingURL(_ url: URL) {
		if url.isFileURL {
			importedFileURL = url
			return
		}

		guard url.scheme == "timetable" else { return }

		let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
		let dataParam = components?.fragment ?? components?.queryItems?.first(where: { $0.name == "data" })?.value
		guard let dataParam else {
			return
		}

		do {
			receivedTimetableData = try ShareableTimetableData.fromBase64URL(dataParam)
		} catch {
			print("Failed to decode timetable data: \(error)")
		}
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
