//
//  TranscriptPlaceholder.swift
//  PMS Timetable Message Extension
//
//  Created by Adon Omeri on 30/4/2026.
//

import Messages
import SwiftUI

struct TranscriptPlaceholder: View {
	@State private var messageURL: URL?

	var body: some View {
		VStack(spacing: 12) {
			Image(systemName: "calendar.badge.clock")
				.font(.system(size: 28))
				.foregroundStyle(.blue)

			Text("Timetable")
				.font(.system(.headline, design: .default))

			OpenAppButton(url: messageURL)
		}
		.padding(10)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(UIColor.systemBackground))
		.onAppear {
			loadMessageURL()
		}
	}

	private func loadMessageURL() {
		guard let message = MSConversation().selectedMessage else { return }
		messageURL = message.url
	}
}

struct OpenAppButton: UIViewRepresentable {
	let url: URL?

	func makeUIView(context _: Context) -> UIButton {
		let button = UIButton(type: .system)
		button.setTitle("View in App", for: .normal)

		var config = UIButton.Configuration.filled()
		config.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
		config.baseForegroundColor = .systemBlue
		config.cornerStyle = .medium

		var container = AttributeContainer()
		container.font = .systemFont(ofSize: 12)
		config.attributedTitle = AttributedString("View in App", attributes: container)

		button.configuration = config

		button.addAction(
			UIAction { _ in
				guard let url else { return }
				openURLFromExtension(url, button: button)
			},
			for: .touchUpInside
		)

		return button
	}

	func updateUIView(_: UIButton, context _: Context) {}

	private func openURLFromExtension(_ url: URL, button: UIButton) {
		var responder: UIResponder? = button
		while responder != nil {
			if let application = responder as? UIApplication {
				if #available(iOS 18.0, *) {
					application.open(url, options: [:], completionHandler: nil)
				} else {
					_ = application.perform(NSSelectorFromString("openURL:"), with: url)
				}
				return
			}
			responder = responder?.next
		}
	}
}

#Preview {
	TranscriptPlaceholder()
}
