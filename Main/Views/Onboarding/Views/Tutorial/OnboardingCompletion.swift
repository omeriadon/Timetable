//
//  OnboardingCompletion.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import SwiftUI

struct OnboardingCompletion: View {
	@Environment(\.onboardingPageContext) private var context: OnboardingPageContext

	var body: some View {
		VStack(spacing: 24) {
			Color.clear
				.frame(width: 150, height: 150)
				.glassEffect(.clear.interactive(), in: CheckmarkCircleShape())

			Text("Timetable is ready.")
				.font(.title.bold())

			Text("Finish onboarding to open your timetable.")
				.multilineTextAlignment(.center)
		}
		.onAppear {
			context.configure(canAdvance: true)
		}
	}
}

struct CheckmarkCircleShape: Shape {
	func path(in rect: CGRect) -> Path {
		let originalSize = CGSize(width: 20.2832, height: 19.9316)

		let scale = min(
			rect.width / originalSize.width,
			rect.height / originalSize.height
		)

		let offset = CGPoint(
			x: rect.midX - originalSize.width * scale / 2,
			y: rect.midY - originalSize.height * scale / 2
		)

		func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
			CGPoint(
				x: offset.x + x * scale,
				y: offset.y + y * scale
			)
		}

		var path = Path()

		// Circle
		path.move(to: point(19.9219, 9.96094))

		path.addCurve(
			to: point(9.96094, 19.9219),
			control1: point(19.9219, 15.4492),
			control2: point(15.459, 19.9219)
		)

		path.addCurve(
			to: point(0, 9.96094),
			control1: point(4.47266, 19.9219),
			control2: point(0, 15.4492)
		)

		path.addCurve(
			to: point(9.96094, 0),
			control1: point(0, 4.46289),
			control2: point(4.47266, 0)
		)

		path.addCurve(
			to: point(19.9219, 9.96094),
			control1: point(15.459, 0),
			control2: point(19.9219, 4.46289)
		)

		path.closeSubpath()

		// Checkmark
		path.move(to: point(12.998, 6.08398))
		path.addLine(to: point(8.82812, 12.7832))
		path.addLine(to: point(6.8457, 10.2246))

		path.addCurve(
			to: point(6.10352, 9.81445),
			control1: point(6.60156, 9.90234),
			control2: point(6.38672, 9.81445)
		)

		path.addCurve(
			to: point(5.32227, 10.6152),
			control1: point(5.66406, 9.81445),
			control2: point(5.32227, 10.1758)
		)

		path.addCurve(
			to: point(5.55664, 11.25),
			control1: point(5.32227, 10.8398),
			control2: point(5.41016, 11.0547)
		)

		path.addLine(to: point(8.00781, 14.2578))

		path.addCurve(
			to: point(8.86719, 14.7363),
			control1: point(8.26172, 14.5996),
			control2: point(8.53516, 14.7363)
		)

		path.addCurve(
			to: point(9.6875, 14.2578),
			control1: point(9.19922, 14.7363),
			control2: point(9.48242, 14.5801)
		)

		path.addLine(to: point(14.2773, 7.03125))

		path.addCurve(
			to: point(14.5215, 6.38672),
			control1: point(14.3945, 6.82617),
			control2: point(14.5215, 6.60156)
		)

		path.addCurve(
			to: point(13.6914, 5.63477),
			control1: point(14.5215, 5.92773),
			control2: point(14.1211, 5.63477)
		)

		path.addCurve(
			to: point(12.998, 6.08398),
			control1: point(13.4375, 5.63477),
			control2: point(13.1836, 5.79102)
		)

		path.closeSubpath()

		return path
	}
}
