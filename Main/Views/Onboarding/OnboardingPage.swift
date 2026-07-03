//
//  OnboardingPage.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import SwiftUI

struct OnboardingPage: Identifiable {
	let id: String
	let title: String
	let content: @MainActor () -> AnyView
	let isVisible: @MainActor () -> Bool

	init(
		id: String,
		title: String,
		isVisible: @escaping @MainActor () -> Bool = { true },
		@ViewBuilder content: @escaping @MainActor () -> some View
	) {
		self.id = id
		self.title = title
		self.isVisible = isVisible
		self.content = { AnyView(content()) }
	}
}
