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
		VStack {
			Text("Tap the share button at the right of the tab bar to bring up a list of timetables to share, select one, and then just tap your iPhone with your friend's iPhone to share a timetable.")
				.font(.title2)

			Image("onboarding/shareButton")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.padding(40)
		}
		.onAppear {
			context.configure(canAdvance: true)
		}
	}
}

#Preview {
	WidgetTutorial()
}
