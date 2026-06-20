//
//  App Intent Shared.swift
//  Timetable
//
//  Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import Foundation

struct MyIntent: AppIntent {
	static var title: LocalizedStringResource = "Do Something"

	func perform() async throws -> some IntentResult {
		// logic
		return .result()
	}
}
