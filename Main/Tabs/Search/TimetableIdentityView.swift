import SwiftUI

struct TimetableIdentityView: View {
	static let rowScale: CGFloat = 17 / 28

	enum Prominence {
		case row
		case header
	}

	let result: TimetableSearchResult
	let prominence: Prominence

	private var scale: CGFloat {
		prominence == .row ? Self.rowScale : 1
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(result.title.count > 17 ? "\(result.title.prefix(14))..." : result.title)
				.lineLimit(1)
				.font(.system(size: 29, weight: .regular, design: .monospaced))

			Text("By \(result.authorDisplayName.prefix(20))")
				.font(.system(size: 27, design: .monospaced))
				.foregroundStyle(Color.gray)
		}
		.multilineTextAlignment(.leading)
		.scaleEffect(scale, anchor: .leading)
		.fixedSize(horizontal: true, vertical: true)
	}
}
