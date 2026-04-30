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
		NavigationStack {
			VStack {
				if classes.isEmpty {
					Text("No classes found in your timetable. Import your schedule in the app first to share your timetable.")
						.foregroundStyle(.secondary)
				} else {
					List {
						ForEach(classes, id: \.id) { classItem in
							HStack(spacing: 12) {
								Image(systemName: classItem.symbol)

								Text(classItem.id)

								Spacer()

								Text("\(classItem.slots.count) slot\(classItem.slots.count == 1 ? "" : "s")")
							}
							.listRowSeparator(.hidden)
							.listRowBackground(
								classItem.colour.swiftUIColor.opacity(0.5)
							)
						}
					}
					.scrollBounceBehavior(.basedOnSize)
					.scrollContentBackground(.hidden)

					Button(action: sendTimetable) {
						HStack(spacing: 8) {
							if isSending {
								ProgressView()
									.transition(.blurReplace)
							} else {
								Image(systemName: "paperplane")
									.transition(.blurReplace)
							}

							Text("Send Timetable")
								.contentTransition(.numericText())
						}
						.animation(.easeInOut, value: isSending)
					}
					.tint(.blue)
					.buttonStyle(.glassProminent)
					.buttonBorderShape(.capsule)
					.buttonSizing(.flexible)
					.controlSize(.large)
					.disabled(isSending || classes.isEmpty || senderName.trimmingCharacters(in: .whitespaces).isEmpty)
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
			}
			.padding()
		}
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
