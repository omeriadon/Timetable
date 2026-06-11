//
//  Rectangle.swift
//  Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import SwiftUI

#if os(iOS)
	struct rectangle<Content: View>: View {
		let fill: Color
		let isBreak: Bool
		let content: Content

		init(
			_ fill: Color,
			_ isBreak: Bool = false,
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
			.padding(5)
			.glassEffect(
				!isBreak ? .regular.tint(fill).interactive() : .identity,
				in: RoundedRectangle(cornerRadius: isBreak ? 8 : 10)
			)
			.contentShape(Rectangle())
		}
	}

#elseif os(watchOS)
	struct rectangle<Content: View>: View {
		let fill: Color
		let isBreak: Bool
		let content: Content

		init(
			_ fill: Color,
			_ isBreak: Bool = false,
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
			.glassEffect(
				!isBreak ? .regular.tint(fill).interactive() : .identity,
				in: RoundedRectangle(cornerRadius: isBreak ? 1 : 4)
			)
		}
	}
#endif
