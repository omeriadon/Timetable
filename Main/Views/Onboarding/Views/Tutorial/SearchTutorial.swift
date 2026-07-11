import SwiftUI

struct SearchTutorial: View {
	@Environment(\.onboardingPageContext) private var context

	var body: some View {
		VStack(spacing: 28) {
			Text("Find timetables shared by people at your school.")
				.font(.title2)
				.multilineTextAlignment(.center)

			Image("onboarding/search")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.padding(.horizontal, 20)

			Text("Open Search to discover public timetables and add them to Timetable.")
				.multilineTextAlignment(.center)
		}
		.onAppear {
			context.configure(canAdvance: true)
		}
	}
}

#Preview {
	SearchTutorial()
}
