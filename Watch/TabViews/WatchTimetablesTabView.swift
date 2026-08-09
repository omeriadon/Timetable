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
	let height: CGFloat
	let verticalInset: CGFloat
	let cornerRadius: CGFloat
	let scrollTransitionIntensity: CGFloat
	let usesBackground: Bool
	@ViewBuilder var content: Content

	init(
		height: CGFloat,
		verticalInset: CGFloat,
		cornerRadius: CGFloat = 24,
		scrollTransitionIntensity: CGFloat = 1,
		usesBackground: Bool = true,
		@ViewBuilder content: () -> Content
	) {
		self.height = height
		self.verticalInset = verticalInset
		self.cornerRadius = cornerRadius
		self.scrollTransitionIntensity = scrollTransitionIntensity
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
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		)
		.padding(.horizontal, 8)
		.padding(.vertical, verticalInset)
		.frame(height: height)
//		.scrollTransition(axis: .vertical) { view, phase in
//			let magnitude = min(abs(phase.value), 1) * scrollTransitionIntensity
//			return view
//				.scaleEffect(1 - magnitude * 0.1)
//				.blur(radius: magnitude * 3)
//				.opacity(1 - magnitude * 0.2)
//		}
		.listRowInsets(EdgeInsets())
		.listRowBackground(Color.clear)
	}
}

struct WatchTimetablesTabView: View {
	private enum PageID: Hashable {
		case timetable
		case currentSubject
		case friend(UUID)
	}

	@Default(.friends) private var friends
	@Default(.timetable) private var subjects
	@State private var crownPosition = 0.0

	private let peekHeight: CGFloat = 18
	private let secondaryCardHeightReduction: CGFloat = 36
	private let verticalCardInset: CGFloat = 8

	private var pageIDs: [PageID] {
		var pageIDs: [PageID] = [.timetable]

		if !subjects.isEmpty {
			pageIDs.append(.currentSubject)
		}

		pageIDs.append(contentsOf: friends.compactMap { friend in
			guard friend.timetable != nil else { return nil }
			return .friend(friend.id)
		})

		return pageIDs
	}

	var body: some View {
		GeometryReader { proxy in
			let pageHeight = max(
				1,
				proxy.size.height - peekHeight * 2 - secondaryCardHeightReduction
			)
			let verticalContentMargin = max(0, (proxy.size.height - pageHeight) / 2)
			let maximumCrownPosition = Double(max(1, pageIDs.count - 1))

			ScrollViewReader { scrollProxy in
				List {
					WatchPage(
						height: pageHeight,
						verticalInset: verticalCardInset,
						usesBackground: false
					) {
						ContentView()
					}
					.drawingGroup(opaque: false)
					.id(PageID.timetable)

					if !subjects.isEmpty {
						WatchPage(
							height: pageHeight,
							verticalInset: verticalCardInset
						) {
							CurrentSubjectView()
						}
						.id(PageID.currentSubject)
					}

					ForEach(friends) { friend in
						if let timetable = friend.timetable {
							WatchPage(
								height: pageHeight,
								verticalInset: verticalCardInset
							) {
								FriendsTimetablesView(friend: friend, timetable: timetable)
							}
							.id(PageID.friend(friend.id))
						}
					}
				}
				.listStyle(.plain)
				.scrollContentBackground(.hidden)
				.contentMargins(.vertical, verticalContentMargin, for: .scrollContent)
				.scrollClipDisabled()
				.focusable()
				.digitalCrownRotation(
					$crownPosition,
					from: 0,
					through: maximumCrownPosition,
					by: 1,
					sensitivity: .medium,
					isContinuous: false,
					isHapticFeedbackEnabled: true
				)
				.onChange(of: crownPosition) { _, newPosition in
					let requestedIndex = Int(newPosition.rounded())
					let index = min(requestedIndex, pageIDs.count - 1)

					withAnimation(.smooth) {
						scrollProxy.scrollTo(pageIDs[index], anchor: .center)
					}
				}
			}
		}
		.dynamicTypeSize(.xSmall)
		.ignoresSafeArea(.container, edges: .vertical)
		.background {
			WatchPaperBackground(imageName: "paperBlack", cornerRadius: 0)
				.ignoresSafeArea()
		}
	}
}
