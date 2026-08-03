#if !os(watchOS)
	import SwiftUI

	struct PlatformFrame {
		let width: CGFloat?
		let height: CGFloat?
		let minWidth: CGFloat?
		let idealWidth: CGFloat?
		let maxWidth: CGFloat?
		let minHeight: CGFloat?
		let idealHeight: CGFloat?
		let maxHeight: CGFloat?
		let alignment: Alignment

		private let usesFixedSize: Bool

		init(
			width: CGFloat? = nil,
			height: CGFloat? = nil,
			alignment: Alignment = .center
		) {
			self.width = width
			self.height = height
			minWidth = nil
			idealWidth = nil
			maxWidth = nil
			minHeight = nil
			idealHeight = nil
			maxHeight = nil
			self.alignment = alignment
			usesFixedSize = true
		}

		init(
			minWidth: CGFloat? = nil,
			idealWidth: CGFloat? = nil,
			maxWidth: CGFloat? = nil,
			minHeight: CGFloat? = nil,
			idealHeight: CGFloat? = nil,
			maxHeight: CGFloat? = nil,
			alignment: Alignment = .center
		) {
			width = nil
			height = nil
			self.minWidth = minWidth
			self.idealWidth = idealWidth
			self.maxWidth = maxWidth
			self.minHeight = minHeight
			self.idealHeight = idealHeight
			self.maxHeight = maxHeight
			self.alignment = alignment
			usesFixedSize = false
		}

		@ViewBuilder
		func apply(to content: some View) -> some View {
			if usesFixedSize {
				content.frame(
					width: width,
					height: height,
					alignment: alignment
				)
			} else {
				content.frame(
					minWidth: minWidth,
					idealWidth: idealWidth,
					maxWidth: maxWidth,
					minHeight: minHeight,
					idealHeight: idealHeight,
					maxHeight: maxHeight,
					alignment: alignment
				)
			}
		}
	}

	private struct TwoPlatformPaddingModifier: ViewModifier {
		@Environment(\.appPresentation) private var appPresentation

		let edges: Edge.Set
		let iOS: CGFloat
		let macOS: CGFloat

		func body(content: Content) -> some View {
			content.padding(
				edges,
				appPresentation.value(
					iOS: iOS,
					macOS: macOS
				)
			)
		}
	}

	private struct ThreePlatformPaddingModifier: ViewModifier {
		@Environment(\.appPresentation) private var appPresentation

		let edges: Edge.Set
		let iOS: CGFloat
		let iPadOS: CGFloat
		let macOS: CGFloat

		func body(content: Content) -> some View {
			content.padding(
				edges,
				appPresentation.value(
					iOS: iOS,
					iPadOS: iPadOS,
					macOS: macOS
				)
			)
		}
	}

	private struct TwoPlatformFrameModifier: ViewModifier {
		@Environment(\.appPresentation) private var appPresentation

		let iOS: PlatformFrame
		let macOS: PlatformFrame

		func body(content: Content) -> some View {
			appPresentation.value(
				iOS: iOS,
				macOS: macOS
			)
			.apply(to: content)
		}
	}

	private struct ThreePlatformFrameModifier: ViewModifier {
		@Environment(\.appPresentation) private var appPresentation

		let iOS: PlatformFrame
		let iPadOS: PlatformFrame
		let macOS: PlatformFrame

		func body(content: Content) -> some View {
			appPresentation.value(
				iOS: iOS,
				iPadOS: iPadOS,
				macOS: macOS
			)
			.apply(to: content)
		}
	}

	extension View {
		func padding(
			_ edges: Edge.Set = .all,
			iOS: CGFloat,
			macOS: CGFloat
		) -> some View {
			modifier(
				TwoPlatformPaddingModifier(
					edges: edges,
					iOS: iOS,
					macOS: macOS
				)
			)
		}

		func padding(
			_ edges: Edge.Set = .all,
			iOS: CGFloat,
			iPadOS: CGFloat,
			macOS: CGFloat
		) -> some View {
			modifier(
				ThreePlatformPaddingModifier(
					edges: edges,
					iOS: iOS,
					iPadOS: iPadOS,
					macOS: macOS
				)
			)
		}

		func frame(
			iOS: PlatformFrame,
			macOS: PlatformFrame
		) -> some View {
			modifier(
				TwoPlatformFrameModifier(
					iOS: iOS,
					macOS: macOS
				)
			)
		}

		func frame(
			iOS: PlatformFrame,
			iPadOS: PlatformFrame,
			macOS: PlatformFrame
		) -> some View {
			modifier(
				ThreePlatformFrameModifier(
					iOS: iOS,
					iPadOS: iPadOS,
					macOS: macOS
				)
			)
		}
	}
#endif
