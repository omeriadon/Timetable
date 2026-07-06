import SwiftUI

struct WatchSessionRootView: View {
	let sessionStore: SessionStore

	var body: some View {
		ZStack {
			switch sessionStore.state {
				case .signedOut:
					WatchSignInView()
						.transition(.blurReplace)
				case .restoring:
					ProgressView("Restoring Account…")
						.transition(.blurReplace)
				case .authenticated:
					WatchRootTabView()
						.transition(.identity)
						.transaction { transaction in
							transaction.animation = nil
						}
			}
		}
		.animation(.easeInOut, value: sessionStore.state)
	}
}
