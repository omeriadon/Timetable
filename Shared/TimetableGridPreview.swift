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

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: classes)

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

					ForEach(TimetableLayout.sessions, id: \.self) { session in
						Text(session)
							.font(.caption2)
							.foregroundStyle(
								TimetableLayout.isBreakSession(label: session)
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
							Text(TimetableLayout.shortDayLabels[day])
								.font(.caption2.weight(.semibold))
								.foregroundStyle(.white.opacity(0.78))
								.frame(height: 18)

							ForEach(0 ..< TimetableLayout.sessions.count, id: \.self) { session in
								cell(day: day, session: session, classLookup: classLookup)
									.frame(height: rowHeight(for: TimetableLayout.sessions[session]))
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

	private func cell(day: Int, session: Int, classLookup: [Slot: Class]) -> some View {
		Group {
			if TimetableLayout.isBreakSession(index: session) {
				RoundedRectangle(cornerRadius: 5)
					.fill(.clear)
			} else if TimetableLayout.isUnavailable(day: day, session: session) {
				RoundedRectangle(cornerRadius: 7)
					.fill(.clear)
			} else if let classItem = classLookup[Slot(day, session)] {
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

	private func rowHeight(for session: String) -> CGFloat {
		(TimetableLayout.isBreakSession(label: session) ? 5 : 30) * rowScale
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
