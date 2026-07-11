import SwiftUI

struct FriendsTutorial: View {
	@Environment(\.onboardingPageContext) private var context

	var body: some View {
		VStack(spacing: 28) {
			Text("Keep up with your friends' current classes.")
				.font(.title2)
				.multilineTextAlignment(.center)

			Image("onboarding/friends")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.padding(.horizontal, 20)

			Text("Received timetables can appear together in the Friends timetable widget.")
				.multilineTextAlignment(.center)
		}
		.onAppear {
			context.configure(canAdvance: true)
		}
	}
}

#Preview {
	FriendsTutorial()
}
