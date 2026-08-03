//
//  scrollEdgeEffect.swift
//  Timetable
//
//  Created by Adon Omeri on 22/7/2026.
//

import SwiftUI

public enum VariableBlurDirection {
	case blurredTopClearBottom
	case blurredBottomClearTop
}

extension View {
	func scrollEdgeEffect(
		direction _: BlackGradientDirection = .darkTopClearBottom,
		offset _: CGFloat = 0.9,
		maxBlurRadius _: CGFloat = 2,
		maximumOpacity _: CGFloat = 0.4
	) -> some View {
		scrollEdgeEffectStyle(.soft, for: .all)
	}
}
