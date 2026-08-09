import Defaults
import SwiftUI

private extension View {
	func watchCardStyle(cornerRadius: CGFloat = 24) -> some View {
		background {
			WatchPaperBackground(imageName: "paper", cornerRadius: cornerRadius)
		}
		.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
		.overlay {
			RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
				.strokeBorder(.white.opacity(0.5), lineWidth: 2)
		}
		.foregroundStyle(.white)
	}
}

private struct WatchPaperBackground: View {
	let imageName: String
	let cornerRadius: CGFloat

	var body: some View {
		GeometryReader { proxy in
			Image(imageName)
				.resizable()
				.scaledToFill()
				.frame(width: proxy.size.width, height: proxy.size.height)
				.clipped()
		}
		.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
	}
}

private struct WatchPage<Content: View>: View {
	let verticalInset: CGFloat
	let horizontalPadding: CGFloat
	let cornerRadius: CGFloat
	let pageAlignment: VerticalAlignment
	let usesBackground: Bool
	@ViewBuilder var content: Content

	init(
		verticalInset: CGFloat,
		horizontalPadding: CGFloat,
		cornerRadius: CGFloat = 24,
		pageAlignment: VerticalAlignment = .top,
		usesBackground: Bool = true,
		@ViewBuilder content: () -> Content
	) {
		self.verticalInset = verticalInset
		self.horizontalPadding = horizontalPadding
		self.cornerRadius = cornerRadius
		self.pageAlignment = pageAlignment
		self.usesBackground = usesBackground
		self.content = content()
	}

	@ViewBuilder
	private func styled(_ view: some View) -> some View {
		if usesBackground {
			view.watchCardStyle(cornerRadius: cornerRadius)
		} else {
			view.foregroundStyle(.white)
		}
	}

	var body: some View {
		styled(
			content
				.frame(maxWidth: .infinity)
				.containerRelativeFrame(.vertical) { length, _ in
					max(1, length - verticalInset * 2)
				}
		)
		.padding(.horizontal, horizontalPadding)
		.padding(.vertical, verticalInset)
		.containerRelativeFrame(.vertical, alignment: Alignment(horizontal: .center, vertical: pageAlignment))
		.scrollTransition(axis: .vertical) { view, phase in
			let magnitude = min(abs(phase.value), 1)
			return view
				.scaleEffect(1 - magnitude * 0.04)
				.opacity(1 - magnitude * 0.12)
		}
	}
}

struct WatchTimetablesTabView: View {
	@Default(.friends) private var friends
	@Default(.timetable) private var subjects

	private let cardSpacing: CGFloat = 8
	private let peekHeight: CGFloat = 18
	private let verticalCardInset: CGFloat = 8

	var body: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: cardSpacing) {
				WatchPage(
					verticalInset: verticalCardInset,
					horizontalPadding: 3,
					pageAlignment: .center,
					usesBackground: false
				) {
					ContentView()
				}

				if !subjects.isEmpty {
					WatchPage(verticalInset: verticalCardInset, horizontalPadding: 8) {
						CurrentSubjectView()
					}
				}

				ForEach(friends) { friend in
					if let timetable = friend.timetable {
						WatchPage(verticalInset: verticalCardInset, horizontalPadding: 8) {
							FriendsTimetablesView(friend: friend, timetable: timetable)
						}
					}
				}
			}
			.scrollTargetLayout()
		}
		.contentMargins(.vertical, peekHeight, for: .scrollContent)
		.dynamicTypeSize(.xSmall)
		.scrollTargetBehavior(.viewAligned(limitBehavior: .always))
		.scrollClipDisabled()
		.ignoresSafeArea(.container, edges: .vertical)
		.background {
			WatchPaperBackground(imageName: "paperBlack", cornerRadius: 0)
				.ignoresSafeArea()
		}
	}
}
