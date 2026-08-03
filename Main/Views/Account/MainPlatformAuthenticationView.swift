import Defaults
import SwiftUI

struct MainPlatformAuthenticationView: View {
	@Default(.onboardingPageID) private var onboardingPageID
	let initialPageID: String?

	init(initialPageID: String? = nil) {
		self.initialPageID = initialPageID
	}

	var body: some View {
		NavigationStack {
			ZStack {
				OnboardingBackground(currentPageID: initialPageID ?? onboardingPageID)
					.ignoresSafeArea()

				ScrollView {
					VStack(spacing: 24) {
						Image("Icon")
							.resizable()
							.frame(width: 120, height: 120)
							.shadow(color: .black.opacity(0.35), radius: 15)

						Text("Timetable")
							.font(.largeTitle.bold())

						AccountAuthenticationView(allowsSignUp: true)
					}
					.frame(maxWidth: 560)
					.padding(30)
				}
				.scrollBounceBehavior(.basedOnSize)
			}
		}
		.onAppear {
			if let initialPageID {
				onboardingPageID = initialPageID
			}
		}
	}
}
