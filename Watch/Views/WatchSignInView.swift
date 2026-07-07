import SwiftUI

struct WatchSignInView: View {
	@State private var provisioningService = WatchProvisioningService.shared

	var body: some View {
		VStack(alignment: .center, spacing: 12) {
			Image("Icon")
				.resizable()
				.aspectRatio(contentMode: .fit)

			Text("Sign in on iPhone to sign this Watch in")
				.multilineTextAlignment(.center)
				.lineLimit(3)
				.font(.headline)
				.fontWeight(.regular)

			Button {
				Task {
					provisioningService.requestSessionIfPossible()
				}
			} label: {
				ZStack {
					if provisioningService.isRequesting {
						ProgressView()
							.transition(.blurReplace)
					} else {
						HStack {
							Image(systemName: "iphone.and.arrow.forward")
							Text("Sign In from iPhone")
								.multilineTextAlignment(.leading)
						}
						.transition(.blurReplace)
					}
				}
				.frame(height: 50)
				.animation(.easeInOut(duration: 0.2), value: provisioningService.isRequesting)
			}
			.buttonStyle(.glassProminent)
			.disabled(provisioningService.isRequesting == true)
		}
		.ignoresSafeArea(.all, edges: .vertical)
		.padding(.bottom, 1)
		.padding(.top, 5)
	}
}
