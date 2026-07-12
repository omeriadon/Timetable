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
					if sessionStore.hasCachedAccount {
						WatchRootTabView()
							.transition(.opacity)
					} else {
						WatchSignInView()
							.transition(.blurReplace)
					}
				case .authenticated:
					WatchRootTabView()
						.transition(.opacity)
			}
		}
		.animation(.easeInOut, value: sessionStore.state)
	}
}
