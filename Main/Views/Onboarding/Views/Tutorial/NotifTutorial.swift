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
		VStack {
			Text("Notifications can tell you your next class...")
				.font(.title3)

			Image("onboarding/nextClass")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.padding(.horizontal, 20)

			Spacer()

			Text("Or any special one-off events.")
				.font(.title3)

			Image("onboarding/broadcast")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.padding(.horizontal, 20)

			Spacer()

			Text("Live Activities keep your current class and remaining time visible on the Lock Screen and Dynamic Island.")
				.font(.title3)
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
