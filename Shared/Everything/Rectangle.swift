//
//   Rectangle.swift
//   Shared
//
//   Created by Adon Omeri on 13/5/2026.
//

import SwiftUI

#if os(watchOS)

	struct rectangle<Content: View>: View {
		let fill: Color
		let isBreak: Bool
		let content: Content

		init(
			_ fill: Color,
			isBreak: Bool = false,
			@ViewBuilder content: () -> Content
		) {
			self.fill = fill
			self.isBreak = isBreak
			self.content = content()
		}

		init(_ fill: Color, _ isBreak: Bool = false) where Content == EmptyView {
			self.fill = fill
			self.isBreak = isBreak
			content = EmptyView()
		}

		var body: some View {
			VStack(alignment: .leading) {
				content
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
			}
			.padding(2)
//			.background(fill, in: RoundedRectangle(cornerRadius: isBreak ? 2 : 6))
			.background(
				isBreak ? .clear : fill.opacity(0.72),
				in: RoundedRectangle(cornerRadius: isBreak ? 2 : 6)
			)
			.glassEffect(
				!isBreak ? .clear.tint(fill).interactive()
					: .identity,
				in: RoundedRectangle(cornerRadius: isBreak ? 2 : 6)
			)
		}
	}

#else

	struct rectangle<Content: View>: View {
		let fill: Color
		let isBreak: Bool
		let content: Content
		let selected: Bool

		init(
			_ fill: Color,
			isBreak: Bool = false,
			selected: Bool = false,
			@ViewBuilder content: () -> Content
		) {
			self.fill = fill
			self.isBreak = isBreak
			self.content = content()
			self.selected = selected
		}

		var body: some View {
			VStack(alignment: .leading) {
				content
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
			}
			.padding(5)
			.overlay(
				RoundedRectangle(cornerRadius: isBreak ? 8 : 10)
					.strokeBorder(Color.white, lineWidth: selected ? 2 : 0)
					.transaction { t in
						t.animation = nil
					}
			)
			.glassEffect(
				!isBreak ?
					selected ? .regular.tint(fill).interactive() : .clear.tint(fill).interactive()
					: .identity,
				in: RoundedRectangle(cornerRadius: isBreak ? 8 : 10)
			)
		}
	}

#endif
