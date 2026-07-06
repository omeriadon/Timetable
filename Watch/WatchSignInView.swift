import SwiftUI

struct WatchSignInView: View {
	@State private var provisioningService = WatchProvisioningService.shared

	var body: some View {
		VStack(spacing: 12) {
			Image(systemName: "iphone.and.arrow.forward")
				.font(.title)

			Text("Sign In on iPhone")
				.font(.headline)

			Text("Open Timetable on your paired iPhone, sign in, then connect this Watch.")
				.font(.caption)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)

			Button("Connect", systemImage: "arrow.clockwise", action: provisioningService.requestSessionIfPossible)
				.disabled(provisioningService.isRequesting)
		}
		.padding()
	}
}
