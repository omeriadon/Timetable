//
//  BlackGradientOverlay.swift
//  Timetable
//
//  Created by Adon Omeri on 22/7/2026.
//

import SwiftUI

struct BlackGradientOverlay: View {
	let direction: BlackGradientDirection
	let offset: CGFloat
	let maximumOpacity: CGFloat

	var body: some View {
		GeometryReader { proxy in
			let size = proxy.size

			Rectangle()
				.fill(
					LinearGradient(
						stops: gradientStops,
						startPoint: direction.startPoint,
						endPoint: direction.endPoint
					)
				)
				.frame(width: size.width, height: size.height)
		}
	}

	private var gradientStops: [Gradient.Stop] {
		let logicalOffset = min(max(offset, 0), 1)
		let offset = switch direction {
			case .clearTopDarkBottom: logicalOffset
			case .darkTopClearBottom: 1 - logicalOffset
		}

		let roomBefore = offset
		let roomAfter = 1 - offset

		let beforeScale = min(1, roomBefore / 0.16)
		let afterScale = min(1, roomAfter / 0.18)

		if direction.isDarkAtStart {
			return [
				.init(color: .black.opacity(maximumOpacity), location: 0),
				.init(color: .black.opacity(maximumOpacity * 0.98), location: offset - 0.16 * beforeScale),
				.init(color: .black.opacity(maximumOpacity * 0.90), location: offset - 0.08 * beforeScale),
				.init(color: .black.opacity(maximumOpacity * 0.55), location: offset),
				.init(color: .black.opacity(maximumOpacity * 0.18), location: offset + 0.08 * afterScale),
				.init(color: .clear, location: offset + 0.18 * afterScale),
				.init(color: .clear, location: 1),
			]
		} else {
			return [
				.init(color: .clear, location: 0),
				.init(color: .clear, location: offset - 0.18 * beforeScale),
				.init(color: .black.opacity(maximumOpacity * 0.18), location: offset - 0.08 * beforeScale),
				.init(color: .black.opacity(maximumOpacity * 0.55), location: offset),
				.init(color: .black.opacity(maximumOpacity * 0.90), location: offset + 0.08 * afterScale),
				.init(color: .black.opacity(maximumOpacity * 0.98), location: offset + 0.16 * afterScale),
				.init(color: .black.opacity(maximumOpacity), location: 1),
			]
		}
	}
}

extension View {
	func blackGradientOverlay(
		direction: BlackGradientDirection,
		offset: CGFloat = 0.8,
		maximumOpacity: CGFloat = 0.85
	) -> some View {
		overlay {
			BlackGradientOverlay(
				direction: direction,
				offset: offset,
				maximumOpacity: maximumOpacity
			)
			.ignoresSafeArea()
			.allowsHitTesting(false)
		}
	}
}
