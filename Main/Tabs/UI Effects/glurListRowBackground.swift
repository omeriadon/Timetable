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
			GlurView(radius: 3, offset: 0, interpolation: 0)
		)
	}
}

// 	.glurListRowBackground()
