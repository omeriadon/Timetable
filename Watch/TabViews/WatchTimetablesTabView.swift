import SwiftUI
import WatchKit

private extension View {
	func watchPageTransition(height: CGFloat) -> some View {
		frame(height: height)
			.frame(maxWidth: .infinity)
			.scrollTransition { content, phase in
				content
					.scaleEffect(phase.isIdentity ? 1 : 0.75)
					.blur(radius: phase.isIdentity ? 0 : 8)
			}
	}
}

struct WatchTimetablesTabView: View {
	private var screenHeight: CGFloat {
		WKInterfaceDevice.current().screenBounds.height
	}

	var body: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 0) {
				ForEach(0 ..< 5) { _ in
					Color.blue
						.watchPageTransition(height: screenHeight)
				}
			}
			.scrollTargetLayout()
		}
		.scrollTargetBehavior(.viewAligned)
		.scrollClipDisabled()
		.ignoresSafeArea()
	}
}
