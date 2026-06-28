//
//   CapsuleInputRow.swift
//   Main
//
//   Created by Adon Omeri on 28/6/2026.
//

import SwiftUI

struct CapsuleInputRow: View {
	let title: String
	let systemImage: String
	@Binding var text: String
	var isSecure = false

	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: systemImage)
				.frame(width: 20)
				.foregroundStyle(.secondary)

			ScrollView(.horizontal) {
				Group {
					if isSecure {
						SecureField(title, text: $text)
					} else {
						TextField(title, text: $text)
					}
				}
				.textFieldStyle(.plain)
				.frame(minWidth: 220, alignment: .leading)
			}
			.scrollIndicators(.hidden)
		}
		.padding(.horizontal, 16)
		.frame(minHeight: 50)
		.background(.background, in: .capsule)
		.overlay {
			Capsule()
				.stroke(.secondary.opacity(0.4), lineWidth: 1)
		}
	}
}
