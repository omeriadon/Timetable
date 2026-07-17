//
//  StatusBadgeOverlay.swift
//  Timetable
//

import ColorfulX
import SwiftUI

struct StatusBadgeOverlay: View {
	@Environment(\.statusBadgeManager) private var manager
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	@State private var isHoveringMainBadge = false
	@State private var dragOffset: CGFloat = 0

	private var animation: Animation {
		reduceMotion ? .easeInOut(duration: 0.16) : .spring(response: 0.34, dampingFraction: 0.92)
	}

	var body: some View {
		GeometryReader { geometry in
			VStack(spacing: 0) {
				if let mainBadge = manager.mainBadge {
					mainBadgeView(mainBadge, availableWidth: geometry.size.width)
						.transition(mainTransition)
				}

				Spacer(minLength: 0)
			}
			.frame(maxWidth: .infinity)
			.padding(.top, topPadding)
		}
		.monospaced()
		.allowsHitTesting(manager.mainBadge != nil)
		.animation(animation, value: manager.badges)
		.animation(animation, value: manager.activeBadgeID)
		.onChange(of: manager.mainBadge?.id) {
			isHoveringMainBadge = false
			dragOffset = 0
		}
	}

	@ViewBuilder
	private func mainBadgeView(_ badge: StatusBadge, availableWidth: CGFloat) -> some View {
		let content = ZStack {
			#if os(iOS)
				Capsule()
					.fill(.black.opacity(0.25))
			#endif

			StatusBadgeCapsuleFill(badge: badge)

			StatusBadgeBottomFlowLine(badge: badge)

			StatusBadgeContent(
				badge: badge,
				showsClose: isHoveringMainBadge
			)
			.padding(.horizontal, horizontalPadding)
		}
		.frame(width: mainBadgeWidth(availableWidth))
		.frame(height: badgeHeight)
		.contentShape(.capsule)
		.clipShape(.capsule)
		#if os(iOS)
			.glassEffect(.regular.interactive(), in: .capsule)
		#else
			.glassEffect(.clear.interactive(), in: .capsule)
		#endif
			.contentTransition(.interpolate)
			.animation(animation, value: badge)

		#if os(iOS)
			content
				.offset(y: dragOffset)
				.animation(.spring(duration: 0.4, bounce: 0.3), value: dragOffset)
				.gesture(
					DragGesture(minimumDistance: 12)
						.onChanged { value in
							dragOffset = min(0, value.translation.height)
						}
						.onEnded { value in
							if value.translation.height < -36 {
								withAnimation(animation) {
									dragOffset = -300
								} completion: {
									manager.dismissMainBadge()
									dragOffset = 0
								}
							} else {
								withAnimation(animation) {
									dragOffset = 0
								}
							}
						}
				)
		#else
			content
				.onHover { hovering in
					withAnimation(animation) {
						isHoveringMainBadge = hovering
					}
				}
				.onTapGesture {
					withAnimation(animation) {
						manager.dismissMainBadge()
					}
				}
		#endif
	}

	private func mainBadgeWidth(_ availableWidth: CGFloat) -> CGFloat {
		#if os(iOS)
			availableWidth * 0.64
		#else
			250
		#endif
	}

	private var badgeHeight: CGFloat {
		#if os(iOS)
			56
		#else
			48
		#endif
	}

	private var topPadding: CGFloat {
		#if os(iOS)
			12
		#else
			18
		#endif
	}

	private var horizontalPadding: CGFloat {
		#if os(iOS)
			10
		#else
			8
		#endif
	}

	private var mainTransition: some Transition {
		#if os(iOS)
			.offset(y: -300)
		#else
			.blurReplace
		#endif
	}
}

private struct StatusBadgeContent: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	let badge: StatusBadge
	let showsClose: Bool

	var body: some View {
		HStack(spacing: 10) {
			VStack(alignment: .leading, spacing: 2) {
				Text(showsClose ? "Close" : badge.title)
					.font(primaryFont)
					.lineLimit(badge.secondaryText?.isEmpty ?? true ? 2 : 1)
					.contentTransition(.numericText())
					.animation(contentAnimation, value: showsClose ? "Close" : badge.title)

				if !showsClose, let secondaryText = badge.secondaryText, !secondaryText.isEmpty {
					Text(secondaryText)
						.font(secondaryFont)
						.foregroundStyle(.secondary)
						.lineLimit(1)
						.contentTransition(.numericText())
						.animation(contentAnimation, value: secondaryText)
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.leading, textLeadingPadding)

			ZStack {
				indicator
					.id(indicatorID)
					.transition(.blurReplace)
			}
			.frame(width: indicatorContainerSize, height: indicatorContainerSize)
			.animation(contentAnimation, value: indicatorID)
		}
		.animation(
			reduceMotion ? .easeInOut(duration: 0.16) : .spring(response: 0.34, dampingFraction: 0.92),
			value: badge
		)
		.animation(
			reduceMotion ? .easeInOut(duration: 0.16) : .spring(response: 0.34, dampingFraction: 0.92),
			value: showsClose
		)
	}

	private var contentAnimation: Animation {
		reduceMotion ? .easeInOut(duration: 0.16) : .easeInOut
	}

	private var indicatorID: String {
		if showsClose {
			return "close"
		}
		switch badge.view {
			case .progressView: return "progress"
			case .success: return "success"
			case .error: return "error"
			case .warning: return "warning"
			case .info: return "info"
			case .progressViewAndGauge: return "progress-gauge"
		}
	}

	private var primaryFont: Font {
		#if os(iOS)
			.callout.weight(.semibold).scaled(by: 1.1)
		#else
			.system(size: 13, weight: .semibold)
		#endif
	}

	private var secondaryFont: Font {
		#if os(iOS)
			.caption
		#else
			.system(size: 11)
		#endif
	}

	private var indicatorContainerSize: CGFloat {
		#if os(iOS)
			38
		#else
			30
		#endif
	}

	private var textLeadingPadding: CGFloat {
		#if os(iOS)
			8
		#else
			7
		#endif
	}

	@ViewBuilder
	private var indicator: some View {
		if showsClose {
			statusSymbol("xmark.circle", color: .secondary)
		} else {
			switch badge.view {
				case .progressView:
					ProgressView().controlSize(progressControlSize)
				case .success:
					statusSymbol("checkmark.circle.fill", color: .green, isTerminal: true)
				case .error:
					statusSymbol("xmark.circle.fill", color: .red, isTerminal: true)
				case .warning:
					statusSymbol("exclamationmark.triangle.fill", color: .orange, isTerminal: true)
				case .info:
					statusSymbol("info.circle.fill", color: .blue, isTerminal: true)
				case let .progressViewAndGauge(currentStep, totalSteps):
					StatusBadgeGauge(
						currentStep: currentStep,
						totalSteps: totalSteps,
						containsProgress: true,
						combinedProgressControlSize: combinedProgressControlSize,
						reduceMotion: reduceMotion
					)
			}
		}
	}

	private func statusSymbol(_ name: String, color: Color, isTerminal: Bool = false) -> some View {
		Image(systemName: name)
			.font(.system(size: isTerminal ? terminalSymbolSize : symbolSize, weight: .semibold))
			.symbolRenderingMode(.hierarchical)
			.foregroundStyle(color)
			.contentTransition(.symbolEffect(.replace))
	}

	private var progressControlSize: ControlSize {
		#if os(iOS)
			.regular
		#else
			.small
		#endif
	}

	private var combinedProgressControlSize: ControlSize {
		#if os(iOS)
			.small
		#else
			.mini
		#endif
	}

	private var symbolSize: CGFloat {
		#if os(iOS)
			25
		#else
			22
		#endif
	}

	private var terminalSymbolSize: CGFloat {
		#if os(iOS)
			27
		#else
			20
		#endif
	}
}

private struct StatusBadgeGauge: View {
	let currentStep: Int
	let totalSteps: Int
	let containsProgress: Bool
	let combinedProgressControlSize: ControlSize
	let reduceMotion: Bool

	var body: some View {
		Gauge(
			value: Double(currentStep),
			in: 0 ... Double(totalSteps)
		) {
			EmptyView()
		} currentValueLabel: {
			EmptyView()
		}
		.gaugeStyle(.accessoryCircularCapacity)
		.tint(.white)
		.foregroundStyle(.white)
		.scaleEffect(0.58)
		.frame(width: 24, height: 24)
		.overlay {
			if containsProgress {
				ProgressView()
					.controlSize(combinedProgressControlSize)
			}
		}
	}
}

private struct StatusBadgeCapsuleFill: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	let badge: StatusBadge

	private let loadingPatternScale: CGFloat = 3.4

	private static let loadingColors: [Color] = [
		Color(red: 0.05, green: 0.26, blue: 1.00),
		Color(red: 0.10, green: 0.52, blue: 1.00),
		Color(red: 0.00, green: 0.74, blue: 1.00),
		Color(red: 0.88, green: 0.96, blue: 1.00),
		Color(red: 0.13, green: 0.92, blue: 0.70),
		Color(red: 1.00, green: 0.82, blue: 0.18),
		Color(red: 0.04, green: 0.34, blue: 0.95),
		Color(red: 0.18, green: 0.42, blue: 1.00),
	]

	var body: some View {
		ZStack {
			switch badge.view {
				case .success:
					terminalFill(.green)

				case .error:
					terminalFill(.red)

				case .warning:
					terminalFill(.orange)

				case .info:
					terminalFill(.blue)

				case .progressView, .progressViewAndGauge:
					loadingFill
			}
		}
		.allowsHitTesting(false)
	}

	private func terminalFill(_ color: Color) -> some View {
		LinearGradient(
			stops: [
				.init(color: color.opacity(0.0), location: 0.00),
				.init(color: color.opacity(0.18), location: 0.5),
				.init(color: color.opacity(0.50), location: 1.00),
			],
			startPoint: .top,
			endPoint: .bottom
		)
	}

	@State private var colourfulColors = Self.loadingColors
	@State private var colourfulSpeed: Double = 2.5
	@State private var colourfulBias: Double = 0.0012
	@State private var colourfulNoise: Double = 30
	@State private var colourfulTransitionSpeed: Double = 2.0
	@State private var colourfulFrameLimit: Int = 30
	@State private var colourfulRenderScale: Double = 0.9

	private var loadingFill: some View {
		ColorfulView(
			color: $colourfulColors,
			speed: $colourfulSpeed,
			bias: $colourfulBias,
			noise: $colourfulNoise,
			transitionSpeed: $colourfulTransitionSpeed,
			frameLimit: $colourfulFrameLimit,
			renderScale: $colourfulRenderScale
		)
		.onAppear {
			colourfulSpeed = reduceMotion ? 0 : 2.5
		}
		.onChange(of: reduceMotion) {
			colourfulSpeed = reduceMotion ? 0 : 2.5
		}
		.mask {
			LinearGradient(
				stops: [
					.init(color: .white.opacity(0.0), location: 0.00),
					.init(color: .white.opacity(0.15), location: 0.2),
					.init(color: .white.opacity(0.6), location: 0.66),
					.init(color: .white.opacity(1), location: 1.00),

				],
				startPoint: .top,
				endPoint: .bottom
			)
		}
	}
}

private struct StatusBadgeBottomFlowLine: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	let badge: StatusBadge

	private let lineWidth: CGFloat = 2.2

	private static let flowColors: [Color] = [
		Color(red: 0.12, green: 0.44, blue: 1.00),
		Color(red: 0.00, green: 0.76, blue: 1.00),
		Color(red: 0.92, green: 0.98, blue: 1.00),
		Color(red: 0.18, green: 0.94, blue: 0.70),
		Color(red: 1.00, green: 0.82, blue: 0.20),
		Color(red: 0.08, green: 0.32, blue: 1.00),
		Color(red: 0.18, green: 0.55, blue: 1.00),
	]

	var body: some View {
		if showsFlowLine {
			if reduceMotion {
				line(phase: 0.35, pulse: 0.82)
			} else {
				TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
					let time = context.date.timeIntervalSinceReferenceDate
					let phase = CGFloat((time / 4.2).truncatingRemainder(dividingBy: 1))
					let pulse = 0.70 + 0.22 * CGFloat((sin(time * Double.pi * 2 / 1.35) + 1) / 2)

					line(phase: phase, pulse: pulse)
				}
			}
		}
	}

	private var showsFlowLine: Bool {
		switch badge.view {
			case .progressView, .progressViewAndGauge:
				true
			default:
				false
		}
	}

	private func line(phase: CGFloat, pulse: CGFloat) -> some View {
		GeometryReader { proxy in
			let width = max(proxy.size.width, 1)
			let height = max(proxy.size.height, 1)

			ZStack {
				flowingStroke(
					width: width,
					height: height,
					phase: phase,
					lineWidth: lineWidth + 4
				)
				.blur(radius: 3)
				.opacity(0.35 * pulse)

				flowingStroke(
					width: width,
					height: height,
					phase: phase,
					lineWidth: lineWidth
				)
				.opacity(pulse)
			}
			.frame(width: width, height: height)
		}
		.allowsHitTesting(false)
	}

	private func flowingStroke(
		width: CGFloat,
		height: CGFloat,
		phase: CGFloat,
		lineWidth: CGFloat
	) -> some View {
		ZStack {
			LinearGradient(
				colors: Self.flowColors + Self.flowColors + Self.flowColors,
				startPoint: .leading,
				endPoint: .trailing
			)
			.frame(width: width * 3, height: height)
			.offset(x: -width + phase * width)
		}
		.frame(width: width, height: height)
		.mask {
			BottomCapsuleArc(inset: lineWidth / 2)
				.stroke(
					style: StrokeStyle(
						lineWidth: lineWidth,
						lineCap: .round,
						lineJoin: .round
					)
				)
		}
		.mask {
			LinearGradient(
				stops: [
					.init(color: .clear, location: 0.00),
					.init(color: .clear, location: 0.48),
					.init(color: .white.opacity(0.28), location: 0.60),
					.init(color: .white.opacity(0.86), location: 0.78),
					.init(color: .white, location: 1.00),
				],
				startPoint: .top,
				endPoint: .bottom
			)
		}
	}
}

private struct BottomCapsuleArc: Shape {
	let inset: CGFloat

	func path(in rect: CGRect) -> Path {
		let rect = rect.insetBy(dx: inset, dy: inset)
		let radius = rect.height / 2
		let control = radius * 0.5522847498

		var path = Path()

		path.move(to: CGPoint(x: rect.minX, y: rect.midY))

		path.addCurve(
			to: CGPoint(x: rect.minX + radius, y: rect.maxY),
			control1: CGPoint(x: rect.minX, y: rect.midY + control),
			control2: CGPoint(x: rect.minX + radius - control, y: rect.maxY)
		)

		path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))

		path.addCurve(
			to: CGPoint(x: rect.maxX, y: rect.midY),
			control1: CGPoint(x: rect.maxX - radius + control, y: rect.maxY),
			control2: CGPoint(x: rect.maxX, y: rect.midY + control)
		)

		return path
	}
}
