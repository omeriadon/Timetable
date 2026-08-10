import SwiftUI

struct AppPaperBackground: View {
	var body: some View {
		GeometryReader { proxy in
			Image("backgroundPaper")
				.resizable()
				.scaledToFill()
				.frame(width: proxy.size.width, height: proxy.size.height)
				.clipped()
		}
		.ignoresSafeArea()
	}
}

extension View {
	func personalPaperListRow() -> some View {
		listRowBackground(
			Rectangle()
				.fill(.ultraThinMaterial)
		)
	}

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
