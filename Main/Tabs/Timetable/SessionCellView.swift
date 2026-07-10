//
//   SessionCellView.swift
//   Main
//
//   Created by Adon Omeri on 16/6/2026.
//

import IrregularGradient
import SwiftUI

struct SessionCellView: View {
	let day: Int

	let session: Int

	let subjectLookup: [Slot: Subject]

	let selectedSlot: Slot?

	init(_ day: Int, _ session: Int, _ subjectLookup: [Slot: Subject], _ selectedSlot: Slot?) {
		self.day = day
		self.session = session
		self.subjectLookup = subjectLookup
		self.selectedSlot = selectedSlot
	}

	var body: some View {
		Group {
			// break
			if TimetableLayout.isBreakSession(index: session) {
				rectangle(.clear, isBreak: true) {
					IrregularGradient(
						colors: [.yellow, .orange, .pink, .red, .purple, .blue, .cyan, .mint, .green],
						background: Color.clear,
						speed: 2,
						animate: true
					)
				}
				.frame(height: 20)

				// unavailable
			} else if TimetableLayout.isUnavailable(day: day, session: session) {
				Spacer()
					.frame(height: 60)

				// normal
			} else if let c = subjectLookup[Slot(day, session)] {
				rectangle(
					c.colour.swiftUIColor.opacity(0.8),
					isBreak: false,
					selected: Slot(day, session) == selectedSlot
				) {
					Group {
						Image(systemName: c.symbol)
							.font(Device.isIPhone ? .body : .title2)
						Spacer(minLength: 0)
						Text(c.id)
							.lineLimit(2)
							.fixedSize(horizontal: false, vertical: true)
							.font(Device.isIPhone ? .footnote.scaled(by: 0.9) : .headline)
					}
					.dynamicTypeSize(.medium)
				}
				.frame(height: 60)

				// idk
			} else {
				RoundedRectangle(cornerRadius: 10)
					.fill(.white.opacity(0.05))
					.frame(height: 60)
			}
		}
		.foregroundStyle(.white)
	}
}
