//
//  AboutView.swift
//  Timetable
//
//  Created by Adon Omeri on 26/7/2026.
//

import ColorfulX
import GlurBackdrop
import SwiftUI

struct AboutView: View {
	@Environment(\.appPresentation) private var presentation
	@State private var contributors: [AboutContributorResponse] = []
	@State private var loadError: String?
	@State private var pointerLocation: CGPoint?

	var body: some View {
		ScrollView {
			VStack {
				ZStack(alignment: .bottomTrailing) {
					Image("Icon")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.accessibilityHidden(true)
						.frame(width: 200)

					if AppChannel.current != .appStore {
						Text(AppChannel.current.displayName)
							.font(.title2.weight(.semibold))
							.padding(.horizontal, 15)
							.padding(.vertical, 8)
							.foregroundStyle(.primary)
							.glassEffect(
								.clear.tint(AppChannel.current == .debug ? .orange : .blue).interactive(),
								in: Capsule()
							)
							.offset(x: 20, y: 35)
							.padding(.bottom, 30)
					}
				}

				Text("Timetable")
					.font(.largeTitle)
					.bold()
					.fontWidth(.expanded)
					.padding(.bottom, 20)

				VStack(alignment: .leading, spacing: 8) {
					Text("Development")
						.foregroundStyle(.secondary)
						.textCase(.uppercase)
						.padding(.horizontal)

					VStack(spacing: 0) {
						ForEach(contributors) { contributor in
							LabeledContent(contributor.name, value: contributor.role)
								.padding()

							if contributor.id != contributors.last?.id {
								Divider()
									.padding(.horizontal)
							}
						}

						if contributors.isEmpty {
							if let loadError {
								Text(loadError)
									.foregroundStyle(.secondary)
									.padding()
							} else {
								ProgressView()
									.padding()
							}
						}
					}
					.background {
						GlurView(radius: 3, offset: 0, interpolation: 0)
							.clipShape(RoundedRectangle(cornerRadius: 30))
					}
					.environment(\.colorScheme, .dark)

					Text("© \(Calendar.current.component(.year, from: .now).description), JDCQ. All rights reserved.")
						.foregroundStyle(.secondary)
						.padding()
						.frame(maxWidth: .infinity, alignment: .leading)
						.frame(height: 50)
						.background {
							GlurView(radius: 3, offset: 0, interpolation: 0)
								.clipShape(Capsule())
						}
				}
			}
			.padding(.horizontal)
		}
		#if os(macOS)
		.onContinuousHover(coordinateSpace: .local) { phase in
			switch phase {
				case let .active(location):
					pointerLocation = location
				case .ended:
					pointerLocation = nil
			}
		}
		#endif
		.task {
			do {
				contributors = try await AdministrationService.shared.aboutContributors()
			} catch {
				loadError = error.localizedDescription
			}
		}
		.scrollContentBackground(.hidden)
		.scrollEdgeEffect()
		.background {
			if presentation == .iOS {
				AboutBackgroundView(pointerLocation: $pointerLocation)
			}
		}
	}
}

struct AboutBackgroundView: View {
	@Binding private var pointerLocation: CGPoint?
	@State private var colors = [
		Color.brown,
		Color.clear,
		Color.clear,
	]
	@State private var speed = 0.6
	@State private var colorTransitionSpeed = 10.0

	init(pointerLocation: Binding<CGPoint?> = .constant(nil)) {
		_pointerLocation = pointerLocation
	}

	var body: some View {
		GeometryReader { proxy in
			ZStack {
				ColorfulView(
					color: $colors,
					speed: $speed,
					bias: .constant(0.00001),
					noise: .constant(64),
					transitionSpeed: $colorTransitionSpeed,
					frameLimit: .constant(60),
					renderScale: .constant(1)
				)

				if let pointerLocation {
					RadialGradient(
						colors: [
							Color.white.opacity(0.2),
							Color.white.opacity(0.04),
							Color.clear,
						],
						center: UnitPoint(
							x: pointerLocation.x / max(proxy.size.width, 1),
							y: pointerLocation.y / max(proxy.size.height, 1)
						),
						startRadius: 0,
						endRadius: 260
					)
					.blur(radius: 10)
				}
			}
		}
		.ignoresSafeArea()
		.accessibilityHidden(true)
		.allowsHitTesting(false)
	}
}
