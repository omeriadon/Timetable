import SwiftUI

@MainActor
struct AppRouterHost<Content: View>: View {
	@State private var router = AppRouter()
	@State private var activePresentation = AppPresentation.iOS
	@State private var presentationUpdateTask: Task<Void, Never>?
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	private let content: (AppRouter) -> Content

	init(
		@ViewBuilder content: @escaping (AppRouter) -> Content
	) {
		self.content = content
	}

	var body: some View {
		GeometryReader { proxy in
			let resolvedPresentation = AppPresentation.resolve(
				horizontalSizeClass: horizontalSizeClass,
				presentationWidth: proxy.size.width
			)

			content(router)
				.environment(router)
				.environment(\.appPresentation, activePresentation)
				.onAppear {
					apply(resolvedPresentation)
				}
				.onChange(of: resolvedPresentation) { _, presentation in
					schedule(presentation)
				}
				.onDisappear {
					presentationUpdateTask?.cancel()
				}
		}
	}

	private func schedule(_ presentation: AppPresentation) {
		presentationUpdateTask?.cancel()
		presentationUpdateTask = Task { @MainActor in
			try? await Task.sleep(for: .milliseconds(200))
			guard !Task.isCancelled else {
				return
			}
			apply(presentation)
		}
	}

	private func apply(_ presentation: AppPresentation) {
		guard activePresentation != presentation else {
			return
		}
		activePresentation = presentation
		router.updatePresentation(presentation)
	}
}
