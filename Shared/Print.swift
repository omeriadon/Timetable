//
//   Print.swift
//   Shared
//
//   Created by Adon Omeri on 24/6/2026.
//

import Foundation
import os

enum LogCategory: String {
	case account = "Account"
	case database = "Database"
	case defaults = "Defaults"
	case general = "General"
	case intents = "Intents"
	case liveActivity = "LiveActivity"
	case network = "Network"
	case passes = "Passes"
	case server = "Server"
	case spotlight = "Spotlight"
	case wallet = "Wallet"
	case watch = "Watch"
	case widget = "Widget"
}

@Sendable nonisolated func Print(
	_ message: @autoclosure () -> Any,
	category: LogCategory = .general,
	function: StaticString = #function,
	duration: Duration? = nil
) {
	let evaluatedMessage = message()
	let logger = Logger(
		subsystem: Bundle.main.bundleIdentifier ?? "com.omeriadon.timetable",
		category: category.rawValue
	)
	let suffix = duration.map { " [duration=\($0)]" } ?? ""
	logger.debug("[\(String(describing: function), privacy: .public)] \(String(describing: evaluatedMessage), privacy: .public)\(suffix, privacy: .public)")
}

@Sendable nonisolated func PrintError(
	_ message: @autoclosure () -> Any,
	category: LogCategory = .general,
	function: StaticString = #function,
	error: (any Error)? = nil
) {
	let evaluatedMessage = message()
	let logger = Logger(
		subsystem: Bundle.main.bundleIdentifier ?? "com.omeriadon.timetable",
		category: category.rawValue
	)
	let suffix = error.map { " [error=\(String(describing: $0))]" } ?? ""
	logger.error("[\(String(describing: function), privacy: .public)] \(String(describing: evaluatedMessage), privacy: .public)\(suffix, privacy: .public)")
}
