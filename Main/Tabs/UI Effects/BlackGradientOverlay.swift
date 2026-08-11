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

	@Environment(\.colorScheme) var colorScheme

	var inverted: Color {
		if colorScheme == .light {
			.white
		} else {
			.black
		}
	}

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
		let offset = min(max(offset, 0), 1)

		let beforeTransition: CGFloat = 0.05
		let afterTransition: CGFloat = 0.18

		let beforeScale = min(1, offset / beforeTransition)
		let afterScale = min(1, (1 - offset) / afterTransition)

		let clearToDarkStops: [Gradient.Stop] = [
			.init(
				color: .clear,
				location: 0
			),
			.init(
				color: .clear,
				location: offset - beforeTransition * beforeScale
			),
			.init(
				color: inverted.opacity(maximumOpacity * 0.04),
				location: offset
			),
			.init(
				color: inverted.opacity(maximumOpacity * 0.45),
				location: offset + 0.10 * afterScale
			),
			.init(
				color: inverted.opacity(maximumOpacity * 0.98),
				location: offset + afterTransition * afterScale
			),
			.init(
				color: inverted.opacity(maximumOpacity),
				location: 1
			),
		]

		if !direction.isDarkAtStart {
			return clearToDarkStops
		}

		return clearToDarkStops
			.reversed()
			.map {
				Gradient.Stop(
					color: $0.color,
					location: 1 - $0.location
				)
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
