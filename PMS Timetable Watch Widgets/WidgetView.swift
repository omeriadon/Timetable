import SwiftUI

struct WidgetView: View {
	let classes: [Class]
	let displayMode: DisplayMode
	private let sessions = ["1", "2", "R", "3", "4", "L", "5", "6"]
	private var classLookup: [String: Class] {
		var lookup: [String: Class] = [:]
		for c in classes {
			for slot in c.slots {
				let key = "\(slot.day)-\(slot.session)"
				lookup[key] = c
			}
		}
		return lookup
	}

	var body: some View {
		if classes.isEmpty {
			VStack(spacing: 4) {
				Text("No timetable")
					.font(.caption)
				Text("synced yet")
					.font(.caption)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color.gray.opacity(0.2))
		} else {
			HStack(spacing: 0) {
				ForEach(0 ..< 5) { day in
					VStack(spacing: 0) {
						Text(["Mon", "Tue", "Wed", "Thu", "Fri"][day])
							.font(.footnote.scaled(by: 0.5))
							.frame(height: 10)
						ForEach(0 ..< 8) { session in
							sessionCell(day, session)
						}
					}
				}
			}
			.environment(\.dynamicTypeSize, .xSmall)
			.monospaced()
		}
	}

	@ViewBuilder
	func sessionCell(_ day: Int, _ session: Int) -> some View {
		Group {
			if session == 2 || session == 5 {
				Text("")
					.font(.footnote.scaled(by: 0.1))
					.frame(height: 2)
			} else {
				if day == 2 && session == 7 || day == 4 && session == 7 {
					RoundedRectangle(cornerRadius: 0)
						.fill(.clear)
				} else {
					if let c = classLookup["\(day)-\(session)"] {
						VStack(alignment: .leading) {
							switch displayMode {
								case .symbolsOnly:
									HStack {
										Spacer(minLength: 0)
										Image(systemName: c.symbol)
											.resizable()
											.aspectRatio(contentMode: .fit)
											.imageScale(.small)
										Spacer(minLength: 0)
									}
								case .textOnly:
									Text(c.id)
										.lineLimit(1)
										.font(.footnote.scaled(by: 0.45))
							}
						}
						.padding(1)
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
						.foregroundStyle(.white)
						.background(
							RoundedRectangle(cornerRadius: 0)
								.fill(c.colour.swiftUIColor.opacity(0.8))
						)
					} else {
						RoundedRectangle(cornerRadius: 0)
							.fill(.white.opacity(0.05))
					}
				}
			}
		}
		.foregroundStyle(.white)
	}
}
