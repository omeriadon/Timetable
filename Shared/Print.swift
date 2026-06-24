//
//  Print.swift
//  Timetable
//
//  Created by Adon Omeri on 24/6/2026.
//

import Foundation
import os

nonisolated private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.omeriadon.timetable", category: "General")

@Sendable nonisolated public func Print(_ message: @autoclosure () -> Any) {
	#if DEBUG
	let evaluatedMessage = message()
	logger.info("\(String(describing: evaluatedMessage))")
	#endif
}
