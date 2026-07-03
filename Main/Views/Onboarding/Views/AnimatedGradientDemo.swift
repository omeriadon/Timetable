//
//  AnimatedGradientDemo.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import ColorfulX
import SwiftUI

struct AnimatedGradientDemo: View {
	@State private var preset: ColorfulPreset = .aurora
	@State private var speed: Double = 1.0
	@State private var bias: Double = 0.01
	@State private var noise: Double = 8.0
	@State private var transition: Double = 3.5
	@State private var frameLimit: Int = 60
	@State private var renderScale: Double = 1.0

	var body: some View {
		ColorfulView(
			color: $preset,
			speed: $speed,
			bias: $bias,
			noise: $noise,
			transitionSpeed: $transition,
			frameLimit: $frameLimit,
			renderScale: $renderScale
		)
		.ignoresSafeArea()
	}
}
