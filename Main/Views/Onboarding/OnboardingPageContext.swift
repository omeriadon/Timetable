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
	var canAdvance = false
	var isWorking = false
	var statusMessage: String?

	func configure(canAdvance: Bool, isWorking: Bool = false, statusMessage: String? = nil) {
		self.canAdvance = canAdvance
		self.isWorking = isWorking
		self.statusMessage = statusMessage
	}
}

extension EnvironmentValues {
	@Entry var onboardingPageContext = OnboardingPageContext()
}
