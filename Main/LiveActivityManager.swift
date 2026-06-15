//
//  LiveActivityManager.swift
//  Timetable
//
//  Created by Adon Omeri on 14/5/2026.
//

import ActivityKit

final class LiveActivityManager {
	static let shared = LiveActivityManager()

	private init() {}

	func startTestActivity() throws -> Activity<iPhone_Widget_ExtensionAttributes> {
		let attributes = iPhone_Widget_ExtensionAttributes(name: "Test")

		let state = iPhone_Widget_ExtensionAttributes.ContentState(emoji: "🔥")

		return try Activity.request(
			attributes: attributes,
			content: .init(state: state, staleDate: nil),
			pushType: .token
		)
	}
}
