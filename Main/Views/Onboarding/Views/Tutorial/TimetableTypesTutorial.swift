//
//  TimetableTypesTutorial.swift
//  Timetable
//
//  Created by Adon Omeri on 4/7/2026.
//

import Sticker
import SwiftUI

private struct TimetableTypeItem: Identifiable {
	let id = UUID()
	let title: String
	let description: String
	let colour: Color
}

private let items = [
	TimetableTypeItem(
		title: "Owned Timetables",
		description: "A timetable that a user makes for themselves, which means it is verifiably accurate.",
		colour: .blue
	),
	TimetableTypeItem(
		title: "Authored Timetables",
		description: "A user can create a timetable for someone else, for example if they don’t have the app.",
		colour: .yellow
	),
	TimetableTypeItem(
		title: "Received Timetables",
		description: "A timetable that you receive from your friends, or one you imported from Search. Just because you receive a timetable from your friend doesn't mean you can share it with others, it might have privacy settings applied.",
		colour: .green
	),
]

struct TimetableTypesTutorial: View {
	@Environment(\.onboardingPageContext) private var context

	var body: some View {
		VStack(spacing: 20) {
			VStack(alignment: .leading, spacing: 8) {
				ForEach(items) { item in
					HStack(alignment: .top, spacing: 8) {
						Text("•")

						Text("\(Text(item.title).bold().foregroundStyle(item.colour)): \(item.description)")
							.lineLimit(5)
					}
				}
			}

			GlassEffectContainer(spacing: 145) {
				TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
					GeometryReader { proxy in
						let time = timeline.date.timeIntervalSinceReferenceDate
						let size = proxy.size

						ZStack {
							PulsingGlassShape(
								shape: CalendarAndPersonShape(),
								time: time,
								objectSize: 120,
								position: CGPoint(x: size.width * 0.5, y: size.height * 0.24),
								tint: .blue,
								speed: 0.08,
								phase: 0
							)

							PulsingGlassShape(
								shape: CalendarBadgeCheckmarkShape(),
								time: time,
								objectSize: 100,
								position: CGPoint(x: size.width * 0.18, y: size.height * 0.62),
								tint: .green,
								speed: 0.15,
								phase: 0.4
							)

							PulsingGlassShape(
								shape: Person2CropSquareStackShape(),
								time: time,
								objectSize: 140,
								position: CGPoint(x: size.width * 0.82, y: size.height * 0.75),
								tint: .yellow,
								speed: 0.1,
								phase: 1.4
							)
						}
						.frame(maxWidth: .infinity, maxHeight: .infinity)
						.drawingGroup(opaque: false)
					}
				}
			}
		}
		.onAppear {
			context.configure(canAdvance: true)
		}
	}
}

private struct PulsingGlassShape<S: Shape>: View {
	let shape: S
	let time: TimeInterval
	let objectSize: CGFloat
	let position: CGPoint
	let tint: Color
	let speed: Double
	let phase: Double

	var body: some View {
		let scale = pulseScale(
			time: time,
			speed: speed,
			phase: phase,
			minScale: 0.88,
			maxScale: 1.32
		)

		Color.clear
			.frame(width: objectSize, height: objectSize)
			.glassEffect(.clear.tint(tint), in: shape)
			.scaleEffect(scale)
			.position(position)
	}
}

private func pulseScale(
	time: TimeInterval,
	speed: Double,
	phase: Double,
	minScale: CGFloat,
	maxScale: CGFloat
) -> CGFloat {
	let wave = sin((time * speed + phase) * .pi * 2)
	let normalized = (wave + 1) / 2

	return minScale + CGFloat(normalized) * (maxScale - minScale)
}

#Preview {
	TimetableTypesTutorial()
}
