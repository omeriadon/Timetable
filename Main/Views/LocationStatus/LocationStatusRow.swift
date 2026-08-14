//
//  LocationStatusRow.swift
//  Main
//

import Defaults
import SwiftUI

struct LocationStatusRow: View {
	@Binding var showsArrivalStatistics: Bool
	@Default(.accountProfile) private var profile
	@Default(.locationStatus) private var status

	var body: some View {
		Button {
			showsArrivalStatistics = true
		} label: {
			HStack(spacing: 12) {
				if let profile {
					ProfilePicture(
						appearance: profile.appearance,
						photo: profile.photo,
						size: 60,
						badges: profile.badges,
						accessibilityName: profile.displayName
					)
				}

				VStack(alignment: .leading, spacing: 4) {
					Text("You")
						.font(.title3)

					if let status {
						HStack {
							Text(status.title)

							Spacer()

							let prefix = switch status.state {
								case .onCampus:
									"Arrived: "
								case .offCampus:
									"Left: "
								case .withinTenMinutes, .withinFiveMinutes:
									"Updated: "
							}

							Text("\(prefix)\(status.updatedAt, format: .dateTime.hour().minute())")
								.foregroundStyle(.secondary)
						}
					} else {
						Text("Unavailable")
							.foregroundStyle(.secondary)
					}
				}
			}
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
		.foregroundStyle(Color(.inversePrimary))
		.padding(10)
		.padding(.trailing, 10)
		.background {
			GeometryReader { proxy in
				Image("foregroundPaper")
					.resizable()
					.scaledToFill()
					.frame(
						width: proxy.size.width,
						height: proxy.size.height
					)
					.clipped()
					.accessibilityHidden(true)
			}
			.clipShape(
				RoundedRectangle(
					cornerRadius: 28,
					style: .continuous
				)
			)
		}
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
		.contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
		.accessibilityElement(children: .combine)
		.accessibilityLabel(accessibilityLabel)
		.accessibilityHint("Shows your arrival statistics")
	}

	private var accessibilityLabel: String {
		guard let status else {
			return "Your location status, unavailable"
		}

		let prefix = switch status.state {
			case .onCampus:
				"Arrived"
			case .offCampus:
				"Left"
			case .withinTenMinutes, .withinFiveMinutes:
				"Updated"
		}

		return "Your location status, \(status.title), \(prefix) \(status.updatedAt.formatted(date: .omitted, time: .shortened))"
	}
}

private extension LocationStatusItem {
	var title: String {
		switch state {
			case .offCampus:
				"Off Campus"
			case .withinTenMinutes:
				"Within 10 mins"
			case .withinFiveMinutes:
				"Within 5 mins"
			case .onCampus:
				"On Campus"
		}
	}
}
