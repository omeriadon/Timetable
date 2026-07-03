//
//  OnboardingPageContext.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import Observation
import SwiftUI

@MainActor
@Observable
final class OnboardingPageContext {
	var canAdvance: Bool
	var isWorking: Bool
	var statusMessage: String?

	init(canAdvance: Bool = false, isWorking: Bool = false, statusMessage: String? = nil) {
		self.canAdvance = canAdvance
		self.isWorking = isWorking
		self.statusMessage = statusMessage
	}

	func configure(canAdvance: Bool, isWorking: Bool = false, statusMessage: String? = nil) {
		self.canAdvance = canAdvance
		self.isWorking = isWorking
		self.statusMessage = statusMessage
	}
}

extension EnvironmentValues {
	static var context = OnboardingPageContext()

	@Entry var onboardingPageContext = context
}
