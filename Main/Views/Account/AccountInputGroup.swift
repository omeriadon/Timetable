//
//   AccountInputGroup.swift
//   Main
//
//   Created by Adon Omeri on 28/6/2026.
//

import SwiftUI

struct AccountInputGroup: View {
	let title: String
	let systemImage: String
	@Binding var text: String
	let problems: [String]
	var isSecure = false

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			CapsuleInputRow(
				title: title,
				systemImage: systemImage,
				text: $text,
				isSecure: isSecure
			)
			ValidationMessagesView(messages: problems)
		}
	}
}
