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
	func appPaperPresentation() -> some View {
		presentationBackground {
			AppPaperBackground()
		}
		.scrollContentBackground(.hidden)
	}
}
