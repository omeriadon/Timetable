//
//  LocationStatusRow.swift
//  Main
//

import Defaults
import SwiftUI

struct LocationStatusRow: View {
	@Default(.accountProfile) private var profile
	@Default(.locationStatus) private var status

	var body: some View {
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
					.font(.headline)

				if let status {
					HStack {
						Text(status.state == .onCampus ? "On campus" : "Off campus")

						Spacer()

						Text(status.updatedAt, format: .dateTime.hour().minute())
							.foregroundStyle(.secondary)
					}
				} else {
					Text("Status unavailable")
						.foregroundStyle(.secondary)
				}
			}

			Spacer()
		}
		.padding(8)
		.foregroundStyle(.black)
		.padding(18)
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
