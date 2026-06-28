//
//   ValidationMessagesView.swift
//   Main
//
//   Created by Adon Omeri on 28/6/2026.
//

import SwiftUI

struct ValidationMessagesView: View {
	let messages: [String]

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			ForEach(messages, id: \.self) { message in
				Label(message, systemImage: "exclamationmark.circle.fill")
					.font(.caption)
					.foregroundStyle(.red)
					.transition(.blurReplace)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.animation(.snappy, value: messages)
	}
}
