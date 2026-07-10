//
//  NotifTutorial.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import SwiftUI

struct NotifTutorial: View {
	@Environment(\.onboardingPageContext) private var context

	var body: some View {
		VStack(spacing: 50) {
			Text("Notifications can tell you your next class...")
				.font(.title2)

			Image("onboarding/nextClass")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.padding(.horizontal, 20)

			Spacer()
				.frame(height: 40)

			Text("Or any special one-off events.")
				.font(.title2)

			Image("onboarding/broadcast")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.padding(.horizontal, 20)

			Text("Live Activities keep your current class and remaining time visible on the Lock Screen and Dynamic Island.")
				.font(.title2)
				.multilineTextAlignment(.center)
		}
		.onAppear {
			context.configure(canAdvance: true)
		}
	}
}

#Preview {
	WidgetTutorial()
}
