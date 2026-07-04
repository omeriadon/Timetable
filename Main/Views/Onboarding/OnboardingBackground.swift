//
//  OnboardingBackground.swift
//  Timetable
//
//  Created by Codex on 3/7/2026.
//

import ColorfulX
import SwiftUI

enum OnboardingBackgroundStyle: Equatable {
	case colorful(ColorfulPreset, opacity: Double, speed: Double)
	case black
	case custom([Color], opacity: Double, speed: Double)

	static func style(for pageID: String) -> Self {
		switch pageID {
			case "splash":
				.colorful(.aurora, opacity: 1, speed: 1)
			case "calendar":
				.colorful(.watermelon, opacity: 0.8, speed: 0.6)
			case "notifications":
				.colorful(.dandelion, opacity: 0.6, speed: 0.6)
			case "calendar-import":
				.colorful(.winter, opacity: 0.8, speed: 0.6)
			case "account":
				.colorful(.summer, opacity: 0.8, speed: 0.6)
			case "apns":
				.colorful(.sunset, opacity: 0.8, speed: 0.6)
			case "finished":
				.custom([.black, .black, .black, .black, .black, .black, .blue], opacity: 1, speed: 0.8)
			case "actualFinished":
				.colorful(.neon, opacity: 1, speed: 0.8)
			default:
				.black
		}
	}

	var colors: [Color] {
		switch self {
			case let .colorful(preset, opacity, _):
				preset.colors.map { Color($0).opacity(opacity) }
			case let .custom(colours, opacity: opacity, _):
				colours.map { $0.opacity(opacity) }
			case .black:
				Array(repeating: .black, count: 4)
		}
	}
}

struct OnboardingBackground: View {
	let currentPageID: String

	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	@State private var colors = OnboardingBackgroundStyle.style(for: "splash").colors
	@State private var speed = 0.6
	@State private var colorTransitionSpeed = 10.0

	var body: some View {
		ColorfulView(
			color: $colors,
			speed: $speed,
			bias: .constant(0.00001),
			noise: .constant(64),
			transitionSpeed: $colorTransitionSpeed,
			frameLimit: .constant(60),
			renderScale: .constant(1)
		)
		.background(.black)
		.allowsHitTesting(false)
		.ignoresSafeArea()
		.onChange(of: currentPageID, initial: true) { _, pageID in
			updateRenderer(for: OnboardingBackgroundStyle.style(for: pageID))
		}
	}

	private func updateRenderer(for style: OnboardingBackgroundStyle) {
		colorTransitionSpeed = reduceMotion ? 0 : 10
		colors = style.colors
		switch style {
			case let .colorful(_, _, nextSpeed):
				speed = nextSpeed
			case let .custom(_, _, nextSpeed):
				speed = nextSpeed
			case .black: break
		}
	}
}
