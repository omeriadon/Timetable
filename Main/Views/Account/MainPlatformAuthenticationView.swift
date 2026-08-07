import Defaults
import SwiftUI

struct MainPlatformAuthenticationView: View {
	@Default(.hasCompletedOnboarding) private var hasCompletedOnboarding
	@Default(.onboardingPageID) private var onboardingPageID
	@State private var presentsMacOnboarding = false
	let initialPageID: String?

	init(initialPageID: String? = nil) {
		self.initialPageID = initialPageID
	}

	var body: some View {
		NavigationStack {
			ZStack {
				OnboardingBackground(currentPageID: "splash")

				ScrollView {
					AccountAuthenticationView(allowsSignUp: false)
				}
				.scrollBounceBehavior(.basedOnSize)
				.scrollEdgeEffectStyle(.none, for: .vertical)
			}
			.scrollEdgeEffect(offset: 0.8)
			.safeAreaBar(edge: .top, alignment: .center, spacing: 10) {
				Text("Sign in to use Timetable")
					.font(.title)
					.bold()
					.lineLimit(3)
			}
			.safeAreaBar(edge: .bottom) {
				Button {
					onboardingPageID = "account"
					hasCompletedOnboarding = false
				} label: {
					Label("Create an Account", systemImage: "person.badge.plus")
				}
				.buttonStyle(.glassProminent)
				.controlSize(.large)
				.buttonSizing(.flexible)
				.padding(.horizontal, 20)
			}
		}
		.onAppear {
			if let initialPageID {
				onboardingPageID = initialPageID
			}
		}
	}
}
