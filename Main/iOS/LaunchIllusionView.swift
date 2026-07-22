import SwiftUI

struct LaunchIllusionView: View {
	let onFinished: () -> Void
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	@State private var backgroundOpacity = 1.0
	@State private var iconOpacity = 1.0
	@State private var iconBlur = 0.0

	var body: some View {
		ZStack {
			Color.black.opacity(backgroundOpacity)
			Image("Icon")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: 150, height: 150)
				.opacity(iconOpacity)
				.blur(radius: iconBlur)
		}
		.onAppear {
			guard !reduceMotion else {
				onFinished()
				return
			}
			withAnimation(.easeOut(duration: 0.22)) {
				backgroundOpacity = 0
			}
			withAnimation(.easeOut(duration: 0.55)) {
				iconOpacity = 0
				iconBlur = 24
			}
			Task { @MainActor in
				try? await Task.sleep(for: .milliseconds(560))
				onFinished()
			}
		}
	}
}
