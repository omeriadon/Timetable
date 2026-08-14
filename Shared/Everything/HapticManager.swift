//
//  HapticManager.swift
//  Timetable
//
//  Created by Adon Omeri on 11/7/2026.
//

import SwiftUI

#if os(iOS)
	import UIKit
#elseif os(watchOS)
	import WatchKit
#endif

enum HapticEvent {
	case button
	case selection
	case success
	case warning
	case error
}

@MainActor
final class HapticManager {
	static let shared = HapticManager()

	private init() {}

	func play(_ event: HapticEvent) {
		#if os(iOS)
			switch event {
				case .button, .selection:
				let generator = UISelectionFeedbackGenerator()
				generator.prepare()
				generator.selectionChanged()
				case .success, .warning, .error:
				let generator = UINotificationFeedbackGenerator()
				generator.prepare()
				let type: UINotificationFeedbackGenerator.FeedbackType = switch event {
					case .success: .success
					case .warning: .warning
					case .error: .error
					default: .success
				}
				generator.notificationOccurred(type)
			}
		#elseif os(watchOS)
			let type: WKHapticType = switch event {
				case .button, .selection: .click
				case .success: .success
				case .warning: .retry
				case .error: .failure
			}
			WKInterfaceDevice.current().play(type)
		#endif
	}
}

struct HapticButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.opacity(configuration.isPressed ? 0.8 : 1)
			.scaleEffect(configuration.isPressed ? 0.96 : 1)
			.animation(.snappy(duration: 0.15), value: configuration.isPressed)
			.onChange(of: configuration.isPressed) { _, isPressed in
				if isPressed {
					HapticManager.shared.play(.button)
				}
			}
	}
}

extension ButtonStyle where Self == HapticButtonStyle {
	static var haptic: HapticButtonStyle {
		HapticButtonStyle()
	}
}
