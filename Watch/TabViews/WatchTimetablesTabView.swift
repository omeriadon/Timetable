import Defaults
import SwiftUI
import WatchKit

private extension View {
	func watchCardStyle(cornerRadius: CGFloat = 24) -> some View {
		background {
			WatchPaperBackground(imageName: "paper", cornerRadius: cornerRadius)
		}
		.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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
	@ViewBuilder var content: Content

	var body: some View {
		content
			.frame(maxWidth: .infinity)
			.containerRelativeFrame(.vertical) { length, _ in
				max(1, length - verticalInset * 2)
			}
			.watchCardStyle()
			.padding(.horizontal, horizontalPadding)
			.padding(.vertical, verticalInset)
			.containerRelativeFrame(.vertical, alignment: .top)
			.scrollTransition(.animated(.smooth), axis: .vertical) { view, phase in
				let magnitude = min(abs(phase.value), 1)

				return view
					.scaleEffect(1 - magnitude * 0.08)
					.blur(radius: magnitude * 4)
					.opacity(1 - magnitude * 0.2)
			}
	}
}

struct WatchTimetablesTabView: View {
	@Default(.friends) private var friends
	@Default(.timetable) private var subjects

	var body: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 0) {
				WatchPage(verticalInset: 0, horizontalPadding: 3) {
					ContentView()
				}

				if !subjects.isEmpty {
					WatchPage(verticalInset: 4, horizontalPadding: 8) {
						CurrentSubjectView()
					}
				}

				ForEach(friends) { friend in
					if let timetable = friend.timetable {
						WatchPage(verticalInset: 4, horizontalPadding: 8) {
							FriendsTimetablesView(friend: friend, timetable: timetable)
						}
					}
				}
			}
			.scrollTargetLayout()
		}
		.dynamicTypeSize(.xSmall)
		.scrollTargetBehavior(.viewAligned(limitBehavior: .always))
		.scrollClipDisabled()
		.background {
			WatchPaperBackground(imageName: "paperBlack", cornerRadius: 0)
				.ignoresSafeArea()
		}
	}
}
