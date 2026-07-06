import IrregularGradient
import SwiftUI

struct WatchStatusBadgeOverlay: View {
	@Environment(\.statusBadgeManager) private var manager
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	private var animation: Animation {
		reduceMotion ? .easeInOut(duration: 0.16) : .spring(response: 0.34, dampingFraction: 0.92)
	}

	var body: some View {
		GeometryReader { geometry in
			let metrics = WatchBadgeMetrics(availableWidth: geometry.size.width)
			VStack(spacing: 0) {
				if let badge = manager.mainBadge {
					WatchBadgeCapsule(badge: badge, metrics: metrics)
						.transition(reduceMotion ? .opacity : .offset(y: metrics.dismissalDistance))
				}
				Spacer(minLength: 0)
			}
			.frame(maxWidth: .infinity)
			.padding(.top, metrics.topPadding)
		}
		.allowsHitTesting(false)
		.animation(animation, value: manager.badges)
		.animation(animation, value: manager.activeBadgeID)
	}
}

private struct WatchBadgeMetrics {
	let scale: CGFloat

	init(availableWidth: CGFloat) {
		scale = min(max((availableWidth - 12) / 250, 0.68), 1)
	}

	var width: CGFloat {
		250 * scale
	}

	var height: CGFloat {
		48 * scale
	}

	var topPadding: CGFloat {
		18 * scale
	}

	var horizontalPadding: CGFloat {
		8 * scale
	}

	var spacing: CGFloat {
		10 * scale
	}

	var textLeadingPadding: CGFloat {
		7 * scale
	}

	var indicatorSize: CGFloat {
		30 * scale
	}

	var primaryFontSize: CGFloat {
		15 * scale
	}

	var secondaryFontSize: CGFloat {
		12.5 * scale
	}

	var symbolSize: CGFloat {
		22 * scale
	}

	var terminalSymbolSize: CGFloat {
		20 * scale
	}

	var gaugeSize: CGFloat {
		24 * scale
	}

	var lineWidth: CGFloat {
		2.2 * scale
	}

	var glowWidth: CGFloat {
		lineWidth + 4 * scale
	}

	var glowRadius: CGFloat {
		3 * scale
	}

	var dismissalDistance: CGFloat {
		-300 * scale
	}
}

private struct WatchBadgeCapsule: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	let badge: StatusBadge
	let metrics: WatchBadgeMetrics

	var body: some View {
		ZStack {
			Capsule().fill(.black.opacity(0.25))
			WatchBadgeFill(badge: badge)
			WatchBadgeFlowLine(badge: badge, metrics: metrics)
			WatchBadgeContent(badge: badge, metrics: metrics)
				.padding(.horizontal, metrics.horizontalPadding)
		}
		.frame(width: metrics.width, height: metrics.height)
		.clipShape(.capsule)
		.glassEffect(.regular.interactive(), in: .capsule)
		.contentTransition(.interpolate)
		.animation(
			reduceMotion ? .easeInOut(duration: 0.16) : .spring(response: 0.34, dampingFraction: 0.92),
			value: badge
		)
	}
}

private struct WatchBadgeContent: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	let badge: StatusBadge
	let metrics: WatchBadgeMetrics

	var body: some View {
		HStack(spacing: metrics.spacing) {
			VStack(alignment: .leading, spacing: 2 * metrics.scale) {
				Text(badge.title)
					.font(.system(size: metrics.primaryFontSize, weight: .semibold))
					.lineLimit(badge.secondaryText?.isEmpty ?? true ? 2 : 1)
					.contentTransition(.numericText())
				if let secondaryText = badge.secondaryText, !secondaryText.isEmpty {
					Text(secondaryText)
						.font(.system(size: metrics.secondaryFontSize))
						.foregroundStyle(.secondary)
						.lineLimit(1)
						.contentTransition(.numericText())
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.leading, metrics.textLeadingPadding)

			ZStack {
				indicator.id(indicatorID).transition(.blurReplace)
			}
			.frame(width: metrics.indicatorSize, height: metrics.indicatorSize)
		}
		.animation(reduceMotion ? .easeInOut(duration: 0.16) : .easeInOut, value: badge)
	}

	private var indicatorID: String {
		switch badge.view {
			case .progressView: "progress"
			case .success: "success"
			case .error: "error"
			case .warning: "warning"
			case .info: "info"
			case .progressViewAndGauge: "progress-gauge"
		}
	}

	@ViewBuilder private var indicator: some View {
		switch badge.view {
			case .progressView: ProgressView().controlSize(.small)
			case .success: symbol("checkmark.circle.fill", color: .green)
			case .error: symbol("xmark.circle.fill", color: .red)
			case .warning: symbol("exclamationmark.triangle.fill", color: .orange)
			case .info: symbol("info.circle.fill", color: .blue)
			case let .progressViewAndGauge(step, total):
				Gauge(value: Double(step), in: 0 ... Double(max(total, 1))) { EmptyView() } currentValueLabel: { EmptyView() }
					.gaugeStyle(.accessoryCircularCapacity)
					.tint(.white)
					.foregroundStyle(.white)
					.scaleEffect(0.5)
					.frame(width: metrics.gaugeSize, height: metrics.gaugeSize)
					.overlay { ProgressView().controlSize(.mini) }
		}
	}

	private func symbol(_ name: String, color: Color) -> some View {
		Image(systemName: name)
			.font(.system(size: metrics.terminalSymbolSize, weight: .semibold))
			.symbolRenderingMode(.hierarchical)
			.foregroundStyle(color)
			.contentTransition(.symbolEffect(.replace))
	}
}

private struct WatchBadgeFill: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	let badge: StatusBadge

	private static let colors: [Color] = [
		Color(red: 0.05, green: 0.26, blue: 1), Color(red: 0.10, green: 0.52, blue: 1),
		Color(red: 0, green: 0.74, blue: 1), Color(red: 0.88, green: 0.96, blue: 1),
		Color(red: 0.13, green: 0.92, blue: 0.70), Color(red: 1, green: 0.82, blue: 0.18),
		Color(red: 0.04, green: 0.34, blue: 0.95), Color(red: 0.18, green: 0.42, blue: 1),
	]

	var body: some View {
		Group {
			switch badge.view {
				case .success: terminalFill(.green)
				case .error: terminalFill(.red)
				case .warning: terminalFill(.orange)
				case .info: terminalFill(.blue)
				case .progressView, .progressViewAndGauge:
					IrregularGradient(colors: Self.colors, background: Color.blue, speed: 2.5, animate: !reduceMotion)
						.mask {
							LinearGradient(
								stops: [.init(color: .clear, location: 0), .init(color: .white.opacity(0.15), location: 0.2), .init(color: .white.opacity(0.6), location: 0.66), .init(color: .white, location: 1)],
								startPoint: .top,
								endPoint: .bottom
							)
						}
			}
		}
		.allowsHitTesting(false)
	}

	private func terminalFill(_ color: Color) -> some View {
		LinearGradient(
			stops: [.init(color: color.opacity(0), location: 0), .init(color: color.opacity(0.18), location: 0.5), .init(color: color.opacity(0.5), location: 1)],
			startPoint: .top,
			endPoint: .bottom
		)
	}
}

private struct WatchBadgeFlowLine: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	let badge: StatusBadge
	let metrics: WatchBadgeMetrics

	private static let colors: [Color] = [
		Color(red: 0.12, green: 0.44, blue: 1), Color(red: 0, green: 0.76, blue: 1),
		Color(red: 0.92, green: 0.98, blue: 1), Color(red: 0.18, green: 0.94, blue: 0.70),
		Color(red: 1, green: 0.82, blue: 0.20), Color(red: 0.08, green: 0.32, blue: 1),
		Color(red: 0.18, green: 0.55, blue: 1),
	]

	var body: some View {
		if badge.view.showsProgressBackground {
			if reduceMotion {
				line(phase: 0.35, pulse: 0.82)
			} else {
				TimelineView(.animation(minimumInterval: 1 / 30)) { context in
					let time = context.date.timeIntervalSinceReferenceDate
					line(
						phase: CGFloat((time / 4.2).truncatingRemainder(dividingBy: 1)),
						pulse: 0.70 + 0.22 * CGFloat((sin(time * .pi * 2 / 1.35) + 1) / 2)
					)
				}
			}
		}
	}

	private func line(phase: CGFloat, pulse: CGFloat) -> some View {
		GeometryReader { geometry in
			let width = max(geometry.size.width, 1)
			let height = max(geometry.size.height, 1)
			ZStack {
				stroke(width: width, height: height, phase: phase, lineWidth: metrics.glowWidth)
					.blur(radius: metrics.glowRadius).opacity(0.35 * pulse)
				stroke(width: width, height: height, phase: phase, lineWidth: metrics.lineWidth)
					.opacity(pulse)
			}
		}
		.allowsHitTesting(false)
	}

	private func stroke(width: CGFloat, height: CGFloat, phase: CGFloat, lineWidth: CGFloat) -> some View {
		LinearGradient(colors: Self.colors + Self.colors + Self.colors, startPoint: .leading, endPoint: .trailing)
			.frame(width: width * 3, height: height)
			.offset(x: -width + phase * width)
			.frame(width: width, height: height)
			.mask { WatchBottomArc(inset: lineWidth / 2).stroke(style: .init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)) }
			.mask {
				LinearGradient(
					stops: [.init(color: .clear, location: 0), .init(color: .clear, location: 0.48), .init(color: .white.opacity(0.28), location: 0.60), .init(color: .white.opacity(0.86), location: 0.78), .init(color: .white, location: 1)],
					startPoint: .top,
					endPoint: .bottom
				)
			}
	}
}

private struct WatchBottomArc: Shape {
	let inset: CGFloat
	func path(in rect: CGRect) -> Path {
		let rect = rect.insetBy(dx: inset, dy: inset)
		let radius = rect.height / 2
		let control = radius * 0.5522847498
		var path = Path()
		path.move(to: .init(x: rect.minX, y: rect.midY))
		path.addCurve(to: .init(x: rect.minX + radius, y: rect.maxY), control1: .init(x: rect.minX, y: rect.midY + control), control2: .init(x: rect.minX + radius - control, y: rect.maxY))
		path.addLine(to: .init(x: rect.maxX - radius, y: rect.maxY))
		path.addCurve(to: .init(x: rect.maxX, y: rect.midY), control1: .init(x: rect.maxX - radius + control, y: rect.maxY), control2: .init(x: rect.maxX, y: rect.midY + control))
		return path
	}
}
