//
//  ShareTutorial.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import SwiftUI

struct ShareTutorial: View {
	@Environment(\.onboardingPageContext) private var context

	var body: some View {
		ZStack {
			Image("onboarding/shareButton")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.mask {
					LinearGradient(
						stops: [
							.init(color: .white, location: 0),
							.init(color: .white, location: 0.55),
							.init(color: .white.opacity(0.85), location: 0.72),
							.init(color: .white.opacity(0.5), location: 0.90),
							.init(color: .white.opacity(0.5), location: 1),
						],
						startPoint: .bottom,
						endPoint: .top
					)
				}
				.allowsHitTesting(false)

			VariableBlurView(
				maxBlurRadius: 24,
				direction: .blurredTopClearBottom,
				startOffset: 0.4
			)
		}
		.overlay(alignment: .top) {
			Text("Tap the share button at the right of the tab bar to bring up a list of timetables to share, select one, and then just tap your iPhone with your friend's iPhone to share a timetable.")
				.font(.title2)
		}
		.onAppear {
			context.configure(canAdvance: true)
		}
	}
}

#Preview {
	WidgetTutorial()
}
