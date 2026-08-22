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
	@State private var contributors: [AboutContributorResponse] = []
	@State private var loadError: String?
	@State private var colors = [
		Color.brown,
		Color.clear,
		Color.clear,
	]
	@State private var speed = 0.6
	@State private var colorTransitionSpeed = 10.0

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
			ColorfulView(
				color: $colors,
				speed: $speed,
				bias: .constant(0.00001),
				noise: .constant(64),
				transitionSpeed: $colorTransitionSpeed,
				frameLimit: .constant(60),
				renderScale: .constant(1)
			)
			.ignoresSafeArea()
		}
	}
}
