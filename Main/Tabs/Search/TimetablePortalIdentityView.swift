import SwiftUI

@Animatable
struct TimetablePortalIdentityView: View {
	@AnimatableIgnored let result: TimetableSearchResult
	var progress: CGFloat

	private var titleSize: CGFloat {
		17 + (11 * progress)
	}

	private var subtitleSize: CGFloat {
		15 + (5 * progress)
	}

	private var spacing: CGFloat {
		6 - (2 * progress)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: spacing) {
			Text(result.title)
				.font(.system(size: titleSize, weight: .bold, design: .monospaced))
				.lineLimit(2)

			Text("By \(result.authorDisplayName)")
				.font(.system(size: subtitleSize, design: .monospaced))
				.foregroundStyle(.secondary)
				.lineLimit(1)
		}
	}
}
