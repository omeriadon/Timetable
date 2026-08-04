//
//  OnboardingPage.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import SwiftUI

struct OnboardingPage: Identifiable {
	enum Kind: String, Hashable, Sendable {
		case splash
		case calendarPermission
		case account
		case yearGroup
		case calendarImport
		case notifications
		case completion
	}

	let id: String
	let title: String
	let kind: Kind
	let isVisible: Bool

	init(
		id: String,
		title: String,
		kind: Kind,
		isVisible: Bool = true
	) {
		self.id = id
		self.title = title
		self.kind = kind
		self.isVisible = isVisible
	}
}
