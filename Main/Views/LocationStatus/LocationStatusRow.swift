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
							Text(status.state == .onCampus ? "On Campus" : "Off Campus")

							Spacer()

							let prefix = status.state == .onCampus ? "Arrived: " : "Left: "

							Text("\(prefix)\(status.updatedAt, format: .dateTime.hour().minute())")
								.foregroundStyle(.secondary)
						}
					} else {
						Text("Status unavailable")
							.foregroundStyle(.secondary)
					}
				}
			}
		}
		.foregroundStyle(.white)
		.padding(10)
		.padding(.trailing, 10)
		.background {
			GeometryReader { proxy in
				Image("paperBlack")
					.resizable()
					.scaledToFill()
					.frame(
						width: proxy.size.width,
						height: proxy.size.height
					)
					.clipped()
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
	}
}
