import SwiftUI

struct WatchStatusBadgeOverlay: View {
	@Environment(\.statusBadgeManager) private var manager
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	var body: some View {
		if let badge = manager.mainBadge {
			Button(action: manager.dismissMainBadge) {
				HStack(spacing: 8) {
					indicator(for: badge.view)

					VStack(alignment: .leading, spacing: 1) {
						Text(badge.title)
							.font(.caption.bold())
							.lineLimit(1)

						if let secondaryText = badge.secondaryText, !secondaryText.isEmpty {
							Text(secondaryText)
								.font(.caption2)
								.foregroundStyle(.secondary)
								.lineLimit(1)
						}
					}
					.frame(maxWidth: .infinity, alignment: .leading)
				}
				.padding(.horizontal, 10)
				.frame(height: 42)
				.glassEffect(.regular.interactive(), in: .capsule)
			}
			.buttonStyle(.plain)
			.padding(.horizontal, 6)
			.transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
		}
	}

	@ViewBuilder
	private func indicator(for view: StatusBadgeView) -> some View {
		switch view {
			case .progressView:
				ProgressView().controlSize(.mini)
			case .success:
				statusSymbol("checkmark.circle.fill", color: .green)
			case .error:
				statusSymbol("xmark.circle.fill", color: .red)
			case .warning:
				statusSymbol("exclamationmark.triangle.fill", color: .orange)
			case .info:
				statusSymbol("info.circle.fill", color: .blue)
			case let .progressViewAndGauge(currentStep, totalSteps):
				Gauge(value: Double(currentStep), in: 0 ... Double(max(totalSteps, 1))) {
					EmptyView()
				} currentValueLabel: {
					ProgressView().controlSize(.mini)
				}
				.gaugeStyle(.accessoryCircularCapacity)
				.frame(width: 24, height: 24)
		}
	}

	private func statusSymbol(_ name: String, color: Color) -> some View {
		Image(systemName: name)
			.symbolRenderingMode(.hierarchical)
			.foregroundStyle(color)
			.contentTransition(.symbolEffect(.replace))
	}
}
