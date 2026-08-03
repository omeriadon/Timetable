import SwiftUI

@MainActor
struct AppRouterHost<Content: View>: View {
	@State private var router = AppRouter()
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	private let content: (AppRouter) -> Content

	init(
		@ViewBuilder content: @escaping (AppRouter) -> Content
	) {
		self.content = content
	}

	var body: some View {
		GeometryReader { proxy in
			let presentation = AppPresentation.resolve(
				horizontalSizeClass: horizontalSizeClass,
				presentationWidth: proxy.size.width
			)

			content(router)
				.environment(router)
				.environment(\.appPresentation, presentation)
				.onAppear {
					router.updatePresentation(presentation)
				}
				.onChange(of: presentation) { _, presentation in
					router.updatePresentation(presentation)
				}
		}
	}
}
