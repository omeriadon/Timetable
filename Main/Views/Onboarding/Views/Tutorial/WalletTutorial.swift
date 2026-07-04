//
//  WalletTutorial.swift
//  Timetable
//
//  Created by Adon Omeri on 4/7/2026.
//

import Sticker
import SwiftUI

struct WalletTutorial: View {
	@Environment(\.onboardingPageContext) private var context

	var body: some View {
		VStack(spacing: 10) {
			Text("Timetable's \"currency\" is Wallet passes. You can find all of your owned, authored, received, and shared timetables in Wallet. Timetable automatically finds them and syncs them into your app.")
				.font(.title2)
				.padding(.top, 20)

			Image("PlaceholderTimetablePass")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.padding(30)
				.animation(.spring(duration: 0.5, bounce: 0.6, blendDuration: 0)) { view in
					view
						.stickerEffect()
						.stickerPattern(.diamond)
						.stickerNoiseScale(450)
						.stickerNoiseIntensity(1)
						.stickerColorIntensity(1)
						.stickerMotionEffect(.dragGesture(intensity: 0.5))
				}
		}
		.onAppear {
			context.configure(canAdvance: true)
		}
	}
}

#Preview {
	WidgetTutorial()
}
