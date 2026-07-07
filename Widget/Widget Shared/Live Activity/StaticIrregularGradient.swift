//
//  StaticIrregularGradient.swift
//  Timetable
//
//  Created by Adon Omeri on 6/7/2026.
//

import SwiftUI

struct StaticIrregularGradient: View {
	let colors: [Color]
	let background: Color

	var body: some View {
		GeometryReader { geometry in
			ZStack {
				background

				ZStack {
					ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
						Circle()
							.fill(color)
							.frame(
								width: geometry.size.width * scale(for: index),
								height: geometry.size.width * scale(for: index)
							)
							.position(position(for: index, in: geometry.size))
							.opacity(opacity(for: index))
							.blur(radius: blur(for: index))
					}
				}
				.compositingGroup()
				.blur(radius: outerBlur(for: geometry.size))
			}
			.frame(width: geometry.size.width)
			.clipped()
		}
	}

	private func position(for index: Int, in size: CGSize) -> CGPoint {
		let count = max(colors.count - 1, 1)

		let xProgress = CGFloat(index) / CGFloat(count)
		let x = (-0.1 + xProgress * 1.2) * size.width

		let yPattern: [CGFloat] = [
			0.18,
			0.82,
			0.32,
			0.68,
			0.12,
			0.88,
			0.45,
			0.55,
		]

		let y = yPattern[index % yPattern.count] * size.height

		return CGPoint(x: x, y: y)
	}

	private func scale(for index: Int) -> CGFloat {
		let pattern: [CGFloat] = [
			0.42,
			0.34,
			0.48,
			0.30,
			0.44,
			0.36,
			0.50,
			0.32,
		]

		return pattern[index % pattern.count]
	}

	private func opacity(for index: Int) -> Double {
		let pattern: [Double] = [
			0.90,
			0.78,
			0.86,
			0.82,
			0.94,
			0.76,
			0.88,
			0.80,
		]

		return pattern[index % pattern.count]
	}

	private func blur(for index: Int) -> CGFloat {
		let pattern: [CGFloat] = [
			14,
			10,
			18,
			8,
			16,
			12,
			20,
			9,
		]

		return pattern[index % pattern.count]
	}

	private func outerBlur(for size: CGSize) -> CGFloat {
		pow(min(size.width, size.height), 0.65)
	}
}
