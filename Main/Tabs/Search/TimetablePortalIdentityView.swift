import SwiftUI

struct TimetablePortalIdentityView: View {
	let result: TimetableSearchResult
	let isActive: Bool

	var body: some View {
		TimetableIdentityView(result: result, prominence: .header)
			.scaleEffect(isActive ? 1 : TimetableIdentityView.rowScale, anchor: .leading)
	}
}
