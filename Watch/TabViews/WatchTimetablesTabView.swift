import Defaults
import SwiftUI
import WatchKit

private extension View {
	func watchPageTransition(height: CGFloat) -> some View {
		frame(height: height)
			.frame(maxWidth: .infinity)
			.background {
				WatchPaperBackground(
					imageName: "paper",
					cornerRadius: 24
				)
			}
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
			.foregroundStyle(.white)
			.scrollTransition { content, phase in
				content
					.scaleEffect(phase.isIdentity ? 1 : 0.75)
					.blur(radius: phase.isIdentity ? 0 : 8)
			}
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

struct WatchTimetablesTabView: View {
	@Default(.friends) private var friends
	@Default(.timetable) private var subjects

	private var screenHeight: CGFloat {
		WKInterfaceDevice.current().screenBounds.height
	}

	var body: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 0) {
				ContentView()
					.watchPageTransition(height: screenHeight)

				if !subjects.isEmpty {
					CurrentSubjectView()
						.watchPageTransition(height: screenHeight)
				}

				ForEach(friends) { friend in
					if let timetable = friend.timetable {
						FriendsTimetablesView(friend: friend, timetable: timetable)
							.watchPageTransition(height: screenHeight)
					}
				}
			}
			.scrollTargetLayout()
		}
		.scrollTargetBehavior(.viewAligned)
		.scrollClipDisabled()
		.background {
			WatchPaperBackground(imageName: "paperBlack", cornerRadius: 0)
		}
	}
}
