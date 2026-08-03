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
		#if os(iOS)
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
		#else
			NavigationStack {
				ZStack {
					OnboardingBackground(currentPageID: "splash")
						.ignoresSafeArea()

					ScrollView {
						VStack(spacing: 24) {
							Image("Icon")
								.resizable()
								.frame(width: 120, height: 120)
								.shadow(color: .black.opacity(0.35), radius: 15)

							Text("Timetable")
								.font(.largeTitle.bold())

							AccountAuthenticationView(allowsSignUp: false)

							Button {
								presentsMacOnboarding = true
							} label: {
								Label("Start Onboarding", systemImage: "arrow.right.circle")
							}
							.buttonStyle(.glassProminent)
							.controlSize(.large)
						}
						.frame(maxWidth: 560)
						.padding(30)
					}
					.scrollBounceBehavior(.basedOnSize)
				}
			}
			.sheet(isPresented: $presentsMacOnboarding) {
				NavigationStack {
					ZStack {
						OnboardingBackground(currentPageID: "account")
							.ignoresSafeArea()

						ScrollView {
							AccountAuthenticationView(allowsSignUp: true)
								.frame(maxWidth: 560)
								.padding(30)
						}
					}
					.toolbar {
						ToolbarItem(placement: .cancellationAction) {
							Button(role: .cancel) {
								presentsMacOnboarding = false
							}
						}
					}
				}
				.frame(minWidth: 680, minHeight: 620)
			}
		#endif
			.onAppear {
				if let initialPageID {
					onboardingPageID = initialPageID
				}
			}
	}
}
