//
//  CalendarGradient.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import ColorfulX
import SwiftUI

struct CalendarGradient: View {
	@State private var preset: ColorfulPreset = .watermelon
	@State private var speed: Double = 0.4
	@State private var bias: Double = 0.00001
	@State private var noise: Double = 64.0
	@State private var transition: Double = 10.0
	@State private var frameLimit: Int = 120
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
		.opacity(0.6)
	}
}
