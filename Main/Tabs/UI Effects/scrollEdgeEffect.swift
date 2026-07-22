//
//  scrollEdgeEffect.swift
//  Timetable
//
//  Created by Adon Omeri on 22/7/2026.
//

import SwiftUI

extension View {
	func scrollEdgeEffect(
		direction: BlackGradientDirection = .darkTopClearBottom,
		offset: CGFloat = 0.9,
		maxBlurRadius: CGFloat = 2,
		maximumOpacity: CGFloat = 0.3
	) -> some View {
		scrollEdgeEffectStyle(.soft, for: .all)
			.overlay {
				ZStack {
					let direction2: VariableBlurDirection = switch direction {
						case .clearTopDarkBottom:
							.blurredBottomClearTop
						case .darkTopClearBottom:
							.blurredTopClearBottom
					}

					VariableBlurView(
						maxBlurRadius: maxBlurRadius,
						direction: direction2,
						startOffset: offset
					)

					BlackGradientOverlay(
						direction: direction,
						offset: offset,
						maximumOpacity: maximumOpacity
					)
				}
				.ignoresSafeArea()
				.allowsHitTesting(false)
			}
	}
}
