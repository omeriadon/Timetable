//
//  WidgetTutorial.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import SwiftUI

struct WidgetTutorial: View {
	@Environment(\.onboardingPageContext) private var context

	var body: some View {
		VStack(spacing: 50) {
			Text("Timetable has widgets you can add to your homescreen, with more widgets coming.")
				.font(.title2)

			Image("onboarding/widget")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.padding(.horizontal, 30)
		}
		.onAppear {
			context.configure(canAdvance: true)
		}
	}
}

#Preview {
	WidgetTutorial()
}
