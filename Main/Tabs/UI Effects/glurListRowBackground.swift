//
//  glurListRowBackground.swift
//  Timetable
//
//  Created by Adon Omeri on 11/8/2026.
//

import GlurBackdrop
import SwiftUI

extension View {
	func glurListRowBackground() -> some View {
		listRowBackground(
			appBackground()
		)
	}

	func appBackground() -> some View {
		Rectangle()
			.fill(.ultraThinMaterial.opacity(0.8))
	}
}
