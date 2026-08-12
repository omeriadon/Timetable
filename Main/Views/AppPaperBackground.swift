import Defaults
import SwiftUI

struct AppPaperBackground: View {
	@Default(.accountSettings) private var accountSettings

	var body: some View {
		ZStack {
			AppBackgroundSurface(background: accountSettings.appBackground)
				.id(accountSettings.appBackground)
				.transition(.opacity)
		}
		.animation(.easeInOut(duration: 0.25), value: accountSettings.appBackground)
		.ignoresSafeArea()
	}
}

extension View {
	func appPaperBackground() -> some View {
		scrollContentBackground(.hidden)
			.background {
				AppPaperBackground()
			}
	}

	func appPaperPresentation() -> some View {
		presentationBackground {
			AppPaperBackground()
		}
		.appPaperBackground()
	}
}
