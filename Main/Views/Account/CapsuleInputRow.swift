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
				.foregroundStyle(.secondary)

			Group {
				if isSecure {
					SecureField(title, text: $text)
				} else {
					TextField(title, text: $text)
				}
			}
			.textFieldStyle(.plain)
		}
		.padding(.horizontal)
		.frame(minHeight: 44)
		.glassEffect(.regular.tint(.black.mix(with: .white, by: 0.4)).interactive(), in: .capsule)
	}
}
