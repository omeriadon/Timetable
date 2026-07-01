import SwiftUI

struct TimetableIdentityView: View {
	enum Prominence {
		case row
		case header
	}

	let result: TimetableSearchResult
	let prominence: Prominence

	private var titleSize: CGFloat {
		prominence == .row ? 17 : 28
	}

	private var subtitleSize: CGFloat {
		prominence == .row ? 15 : 20
	}

	var body: some View {
		VStack(alignment: .leading, spacing: prominence == .row ? 6 : 4) {
			Text(result.title)
				.font(.system(size: titleSize, weight: .bold, design: .monospaced))
				.lineLimit(2)

			Text("By \(result.authorDisplayName)")
				.font(.system(size: subtitleSize, design: .monospaced))
				.foregroundStyle(.secondary)
				.lineLimit(1)
		}
		.multilineTextAlignment(.leading)
	}
}
