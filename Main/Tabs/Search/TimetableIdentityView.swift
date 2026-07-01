import SwiftUI

struct TimetableIdentityView: View {
	enum Prominence {
		case row
		case header
	}

	let result: TimetableSearchResult
	let prominence: Prominence

	var body: some View {
		VStack(alignment: prominence == .row ? .leading : .center, spacing: prominence == .row ? 6 : 4) {
			Text(result.title)
				.font(prominence == .row ? .headline : .title)
				.bold()
				.lineLimit(2)

			Text("By \(result.authorDisplayName)")
				.font(prominence == .row ? .subheadline : .title3)
				.foregroundStyle(.secondary)
				.lineLimit(1)
		}
		.monospaced()
		.multilineTextAlignment(prominence == .row ? .leading : .center)
	}
}
