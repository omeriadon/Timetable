//
//  TimetableGridPreview.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 1/5/2026.
//

import Defaults
import SwiftUI
#if canImport(UIKit)
	import UIKit
#endif

struct TimetableGridPreview: View {
	let classes: [Class]
	var showsTitle: Bool = true
	var title: String {
		"\(userDisplayName)'s Timetable"
	}

	var subtitle: String?
	var backgroundColor = Color(red: 39 / 255, green: 39 / 255, blue: 41 / 255)
	var rowScale: CGFloat = 1
	var showBackground: Bool = true

	let userDisplayName = Defaults[.userDisplayName]

	private let sessions = ["1", "2", "R", "3", "4", "L", "5", "6"]
	private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri"]

	var body: some View {
		VStack(alignment: .trailing, spacing: 12) {
			VStack(alignment: .leading, spacing: 3) {
				Text(title)
					.font(.headline.weight(.semibold))
					.lineLimit(1)
				if let subtitle {
					Text(subtitle)
						.font(.caption)
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
			}
			.foregroundStyle(.white)
			.opacity(showsTitle ? 1 : 0)

			HStack(alignment: .top, spacing: 4) {
				VStack(spacing: 4) {
					Text("")
						.frame(height: 18)

					ForEach(Array(sessions.enumerated()), id: \.offset) { _, session in
						Text(session)
							.font(.caption2)
							.foregroundStyle(
								session == "R" || session == "L"
									? .white.opacity(0.7)
									: .white
							)
							.frame(height: rowHeight(for: session))
					}
				}
				.frame(width: 28)

				HStack(alignment: .top, spacing: 4) {
					ForEach(0 ..< 5, id: \.self) { day in
						VStack(spacing: 4) {
							Text(dayLabels[day])
								.font(.caption2.weight(.semibold))
								.foregroundStyle(.white.opacity(0.78))
								.frame(height: 18)

							ForEach(0 ..< sessions.count, id: \.self) { session in
								cell(day: day, session: session)
									.frame(height: rowHeight(for: sessions[session]))
							}
						}
					}
				}
			}
		}
		.padding(14)
		.monospaced()
		.background(showBackground ? backgroundColor : .clear)
	}

	private func cell(day: Int, session: Int) -> some View {
		Group {
			if sessions[session] == "R" || sessions[session] == "L" {
				RoundedRectangle(cornerRadius: 5)
					.fill(.clear)
			} else if isUnavailable(day: day, session: session) {
				RoundedRectangle(cornerRadius: 7)
					.fill(.clear)
			} else if let classItem = classFor(day: day, session: session) {
				RoundedRectangle(cornerRadius: 7)
					.fill(classItem.colour.swiftUIColor.opacity(0.82))
					.overlay(alignment: .topLeading) {
						Text(classItem.id)
							.font(.caption2.weight(.semibold))
							.foregroundStyle(.white)
							.lineLimit(2)
							.padding(4)
					}
			} else {
				RoundedRectangle(cornerRadius: 7)
					.fill(.white.opacity(0.05))
			}
		}
	}

	private func classFor(day: Int, session: Int) -> Class? {
		classes.first { classItem in
			classItem.slots.contains { $0.day == day && $0.session == session }
		}
	}

	private func rowHeight(for session: String) -> CGFloat {
		(session == "R" || session == "L" ? 5 : 30) * rowScale
	}

	private func isUnavailable(day: Int, session: Int) -> Bool {
		(day == 2 && session == 7) || (day == 4 && session == 7)
	}
}

#if canImport(UIKit)
	enum TimetablePreviewRenderer {
		@MainActor
		static func image(classes: [Class], title _: String, subtitle: String? = nil) -> UIImage {
			let size = CGSize(width: 630, height: 336)

			let content = TimetableGridPreview(
				classes: classes,
				showsTitle: false,
				subtitle: subtitle
			)
			.frame(width: size.width, height: size.height)
			.background(Color(red: 39 / 255, green: 39 / 255, blue: 41 / 255)) // force fill
			.clipped()

			let renderer = ImageRenderer(content: content)
			renderer.scale = 3

			return renderer.uiImage ?? UIImage()
		}
	}
#endif // canImport(UIKit)
