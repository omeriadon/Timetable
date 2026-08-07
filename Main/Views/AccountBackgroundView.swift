//
//  AccountBackgroundView.swift
//  Timetable
//
//  Created by Adon Omeri on 7/8/2026.
//

import ColorfulX
import SwiftUI

struct AccountBackgroundView: View {
	let profile: AccountProfile?

	@State private var colours: [Color] = [.black, .black]
	@State private var noise: Double = 0
	@State private var speed: Double = 0

	var body: some View {
		ColorfulView(
			color: .constant(colours),
			speed: .constant(speed),
			bias: .constant(0.000000000000001),
			noise: .constant(noise),
			transitionSpeed: .constant(4),
			renderScale: .constant(3)
		)
		.task(id: profile?.id) {
			guard let profile else { return }
			let loaded = await profile.profilePictureColours()
			colours = loaded.map(\.swiftUIColor)
			noise = profile.profilePictureNoise
			speed = profile.profilePictureSpeed
		}
	}
}
