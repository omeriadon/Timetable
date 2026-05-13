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
						HStack {
							Spacer()
							Text(["Mon", "Tue", "Wed", "Thu", "Fri"][day])
								.font(.footnote.scaled(by: 0.5))
								.frame(height: 10)
							Spacer()
						}
						.background(
							day == currentWeekdayIndex
								? Color.white
								: Color.clear
						)
						.foregroundStyle(
							day == currentWeekdayIndex
								? Color.black
								: Color.white
						)

						ForEach(0 ..< 8) { session in
							sessionCell(day, session)
						}
					}
					.overlay(alignment: .leading) {
						if day == currentWeekdayIndex {
							Rectangle()
								.fill(Color.white)
								.frame(width: 1)
						}
					}
					.overlay(alignment: .trailing) {
						if day == currentWeekdayIndex {
							Rectangle()
								.fill(Color.white)
								.frame(width: 1)
						}
					}
					.overlay(alignment: .bottom) {
						if day == currentWeekdayIndex {
							Rectangle()
								.fill(Color.white)
								.frame(height: 1)
						}
					}
				}
			}
			.environment(\.dynamicTypeSize, .xSmall)
			.monospaced()
		}
	}

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
						if day == 0, session == 7 {
							VStack(alignment: .leading) {
								switch displayMode {
									case .symbolsOnly:
										HStack {
											Spacer(minLength: 0)
											Image(systemName: c.symbol)
												.resizable()
												.aspectRatio(contentMode: .fit)
												.frame(height: 9)
											Spacer(minLength: 0)
										}
									case .textOnly:
										GeometryReader { geo in
											Text(c.id)
												.lineLimit(1)
												.font(.footnote.scaled(by: 0.5))
												.padding(.leading, day == currentWeekdayIndex ? 4 : 3)
												.fixedSize(horizontal: true, vertical: false)
												.padding(.trailing, 1)
												.frame(width: geo.size.width, alignment: .leading)
												.clipped()
												.allowsTightening(true)
										}
								}
							}
							.padding(1)
							.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
							.foregroundStyle(.white)
							.background(
								RoundedRectangle(cornerRadius: 0)
									.fill(c.colour.swiftUIColor)
							)
						} else {
							VStack(alignment: .leading) {
								switch displayMode {
									case .symbolsOnly:
										HStack {
											Spacer(minLength: 0)
											Image(systemName: c.symbol)
												.resizable()
												.aspectRatio(contentMode: .fit)
												.frame(height: 9)
											Spacer(minLength: 0)
										}
									case .textOnly:
										GeometryReader { geo in
											Text(c.id)
												.lineLimit(1)
												.font(.footnote.scaled(by: 0.5))
												.padding(.leading, day == currentWeekdayIndex ? 1 : 0)
												.fixedSize(horizontal: true, vertical: false)
												.padding(.trailing, 1)
												.frame(width: geo.size.width, alignment: .leading)
												.clipped()
												.allowsTightening(true)
										}
								}
							}
							.padding(1)
							.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
							.foregroundStyle(.white)
							.background(
								RoundedRectangle(cornerRadius: 0)
									.fill(c.colour.swiftUIColor)
							)
						}
					} else {
						RoundedRectangle(cornerRadius: 0)
							.fill(.white.opacity(0.05))
					}
				}
			}
		}
		.foregroundStyle(.white)
	}

	private var currentWeekdayIndex: Int {
		let weekday = Calendar.current.component(.weekday, from: Date())
		// weekday: 1 = Sunday ... 7 = Saturday
		// convert to 0 = Monday ... 4 = Friday
		return (weekday + 5) % 7
	}
}
