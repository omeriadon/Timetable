import SwiftUI

struct IntentSummaryView: View {
	let title: String
	let detail: String?

	var body: some View {
		VStack(spacing: 8) {
			Text(title)
				.font(.title2.bold())
				.multilineTextAlignment(.center)
			if let detail {
				Text(detail)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
			}
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(ContainerRelativeShape().fill(Color.accentColor.gradient))
		.clipShape(ContainerRelativeShape())
		.monospaced()
	}
}

struct IntentListView: View {
	let title: String
	let values: [String]

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(title)
				.font(.headline)
			ForEach(values, id: \.self) { value in
				Label(value, systemImage: "circle.fill")
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
		.background(ContainerRelativeShape().fill(Color.accentColor.gradient))
		.clipShape(ContainerRelativeShape())
		.monospaced()
	}
}
