//
//  View Extensions.swift
//  Timetable
//
//  Created by Adon Omeri on 9/8/2026.
//

import SwiftUI

extension View {
	@ViewBuilder
	func minimizingToolbarOnScrollDown() -> some View {
		if #available(anyAppleOS 27, *) {
			toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
				.toolbarMinimizationSafeAreaAdjustment(.disabled, for: .navigationBar)
		} else {
			self
		}
	}

	@ViewBuilder
	func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
		if condition {
			transform(self)
		} else {
			self
		}
	}
}
