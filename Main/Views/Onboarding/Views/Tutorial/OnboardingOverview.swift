import SwiftUI

struct OnboardingOverview: View {
	@Environment(\.onboardingPageContext) private var context

	var body: some View {
		VStack(spacing: 24) {
			Image(systemName: "calendar.badge.checkmark")
				.font(.system(size: 76))

			Text("Timetable brings your schedule, reminders, sharing, and widgets together.")
				.font(.title2)
				.multilineTextAlignment(.center)

			Text("Here is a quick overview of what you can do.")
				.multilineTextAlignment(.center)
		}
		.onAppear {
			context.configure(canAdvance: true)
		}
	}
}

#Preview {
	OnboardingOverview()
}
