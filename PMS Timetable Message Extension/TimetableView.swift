//
//  TimetableView.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 29/4/2026.
//

import Defaults
import SwiftUI
import UIKit

struct TimetableView: View {
	@State private var senderName: String
	@State private var isSending = false
	@State private var errorMessage: String?
	@Default(.timetable) var classes
	let sendMessage: (String, [Class], @escaping (Result<Void, Error>) -> Void) -> Void

	init(sendMessage: @escaping (String, [Class], @escaping (Result<Void, Error>) -> Void) -> Void = { _, _, completion in
		completion(.failure(TimetableSendError.unavailable))
	}) {
		self.sendMessage = sendMessage
		_senderName = State(initialValue: Defaults[.userDisplayName])
	}

	var body: some View {
		VStack(spacing: 16) {
			Text("PMS Timetable")
				.font(.headline)

			TextField("Your name", text: $senderName)
				.padding(12)
				.background(Color.gray.opacity(0.1))
				.cornerRadius(8)

			if classes.isEmpty {
				Text("No classes scheduled")
					.foregroundStyle(.secondary)
			} else {
				ScrollView {
					VStack(alignment: .leading, spacing: 8) {
						ForEach(classes, id: \.id) { classItem in
							HStack(spacing: 12) {
								Image(systemName: classItem.symbol)
									.frame(width: 24)

								VStack(alignment: .leading, spacing: 2) {
									Text(classItem.id)
										.font(.subheadline.bold())

									Text("\(classItem.slots.count) slot\(classItem.slots.count == 1 ? "" : "s")")
										.font(.caption)
										.foregroundStyle(.secondary)
								}

								Spacer()
							}
							.padding(8)
							.background(Color.gray.opacity(0.1))
							.cornerRadius(6)
						}
					}
				}
				.frame(maxHeight: 250)
			}

			ZStack {
				if let error = errorMessage {
					Text(error)
						.font(.caption)
						.foregroundStyle(.red)
						.padding(8)
						.background(Color.red.opacity(0.1))
						.cornerRadius(6)
						.transition(.blurReplace)
				}
			}
			.animation(.easeInOut, value: errorMessage)

			Button(action: sendTimetable) {
				HStack(spacing: 8) {
					if isSending {
						ProgressView()
							.transition(.blurReplace)
					} else {
						Image(systemName: "paperplane")
							.transition(.blurReplace)
					}

					Text(isSending ? "Sending..." : "Send Timetable")
						.contentTransition(.numericText())
				}
				.animation(.easeInOut, value: isSending)
			}
			.tint(.blue)
			.buttonStyle(.glassProminent)
			.buttonBorderShape(.capsule)
			.buttonSizing(.flexible)
			.disabled(isSending || classes.isEmpty || senderName.trimmingCharacters(in: .whitespaces).isEmpty)
		}
		.padding()
		.monospaced()
	}

	private func sendTimetable() {
		isSending = true
		errorMessage = nil

		let name = senderName.trimmingCharacters(in: .whitespaces)
		sendMessage(name, classes) { result in
			DispatchQueue.main.async {
				isSending = false
				switch result {
				case .success:
					errorMessage = "Timetable sent!"
					DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
						errorMessage = nil
					}
				case let .failure(error):
					errorMessage = "Error sending: \(error.localizedDescription)"
				}
			}
		}
	}
}

private enum TimetableSendError: LocalizedError {
	case unavailable

	var errorDescription: String? {
		switch self {
		case .unavailable:
			return "Messages conversation is unavailable."
		}
	}
}

#Preview {
	TimetableView()
}
