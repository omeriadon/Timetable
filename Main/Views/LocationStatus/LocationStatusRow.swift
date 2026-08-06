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
					size: 40,
					badges: profile.badges,
					accessibilityName: profile.displayName
				)
			}

			VStack(alignment: .leading, spacing: 4) {
				Text("You")
					.font(.headline)

				if let status {
					Text(status.state == .onCampus ? "On campus" : "Off campus")
					Text(status.updatedAt, format: .relative(presentation: .named))
						.font(.caption)
						.foregroundStyle(.secondary)
				} else {
					Text("Status unavailable")
						.foregroundStyle(.secondary)
				}
			}

			Spacer()
		}
		.padding(8)
	}
}
