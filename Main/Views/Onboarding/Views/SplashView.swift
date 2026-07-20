//
//  SplashView.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import Sticker
import SwiftUI

struct SplashView: View {
	var body: some View {
		VStack(spacing: 50) {
			Image("Icon")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: 300)
				.animation(.spring(duration: 0.5, bounce: 0.8, blendDuration: 0)) { view in
					view
						.stickerEffect()
						.stickerCheckerIntensity(0)
						.stickerCheckerScale(0)
						.stickerColorIntensity(0)
						.stickerBlend(0)
						.stickerMotionEffect(.dragGesture(intensity: 0.6))
				}

			Text("Timetable \(Bundle.main.appVersion)")
				.font(.largeTitle.scaled(by: 1.1))
				.multilineTextAlignment(.center)
		}
		.bold()
	}
}

#Preview {
	SplashView()
}
