//
//  TimetableView.swift
//  Timetable
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
	@Default(.timetable) var subjects
	let sendMessage: (String, [Subject], @escaping (Result<Void, Error>) -> Void) -> Void

	init(sendMessage: @escaping (String, [Subject], @escaping (Result<Void, Error>) -> Void) -> Void = { _, _, completion in
		completion(.failure(TimetableSendError.unavailable))
	}) {
		self.sendMessage = sendMessage
		_senderName = State(initialValue: Defaults[.userDisplayName])
	}

	var body: some View {
		NavigationStack {
			VStack {
				if subjects.isEmpty {
					Text("No subjects found in your timetable. Import your schedule in the app first to share your timetable.")
						.foregroundStyle(.secondary)
				} else {
					Text("Timetable")
						.font(.title)
						.bold()

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
					.tint(.accentColor)
					.buttonStyle(.glassProminent)
					.buttonBorderShape(.capsule)
					.buttonSizing(.flexible)
					.controlSize(.large)
					.disabled(isSending || subjects.isEmpty || senderName.trimmingCharacters(in: .whitespaces).isEmpty)
				}

				Spacer()
			}
			.padding()
		}
		.monospaced()
	}

	private func sendTimetable() {
		isSending = true
		errorMessage = nil

		let name = senderName.trimmingCharacters(in: .whitespaces)
		sendMessage(name, subjects) { result in
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
				"Messages conversation is unavailable."
		}
	}
}

#Preview {
	TimetableView()
}
