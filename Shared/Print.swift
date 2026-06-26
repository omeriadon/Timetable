//
//  Print.swift
//  Timetable
//
//  Created by Adon Omeri on 24/6/2026.
//

import Foundation
import os

private nonisolated let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.omeriadon.timetable", category: "General")

@Sendable public nonisolated func Print(_ message: @autoclosure () -> Any) {
	let evaluatedMessage = message()
	logger.debug("\(String(describing: evaluatedMessage))")
}

@Sendable public nonisolated func PrintError(_ message: @autoclosure () -> Any) {
	let evaluatedMessage = message()
	logger.error("\(String(describing: evaluatedMessage))")
}
