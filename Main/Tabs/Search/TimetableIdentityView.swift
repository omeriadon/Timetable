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
			Text(result.title.count > 19 ? "\(result.title.prefix(16))..." : result.title)
				.lineLimit(1)
				.font(.system(size: 32, weight: .bold, design: .monospaced))
				.fixedSize(horizontal: true, vertical: true)

			Text("By \(result.authorDisplayName)")
				.font(.system(size: 25, design: .monospaced))
				.foregroundStyle(Color.gray)
				.fixedSize(horizontal: true, vertical: true)
		}
		.multilineTextAlignment(.leading)
		.scaleEffect(scale, anchor: .topLeading)
	}
}
