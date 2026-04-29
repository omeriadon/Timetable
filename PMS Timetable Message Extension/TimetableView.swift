//
//  TimetableView.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 29/4/2026.
//

import Defaults
import Messages
import SwiftUI

struct TimetableView: View {
	@State private var isSending = false
	@State private var errorMessage: String?
	@Default(.timetable) var classes

	var body: some View {
		VStack(spacing: 16) {
			Text("PMS Timetable")
				.font(.headline)

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
			.disabled(isSending || classes.isEmpty)
		}
		.padding()
		.onAppear {
			print("[TimetableView] onAppear called - Defaults currently has \(classes.count) classes")
		}
		.monospaced()
	}

	private func sendTimetable() {
		isSending = true
		errorMessage = nil

		do {
			let messageData = try TimetableMessage.encode(
				classes,
				sender: UIDevice.current.name
			)

			let timetableFileURL = FileManager.default.temporaryDirectory
				.appendingPathComponent("Timetable")
				.appendingPathExtension("timetable")

			try messageData.write(to: timetableFileURL, options: .atomic)

			let message = MSMessage()
			message.url = timetableFileURL
			message.accessibilityLabel = "Timetable"

			print("[TimetableView] Timetable file created at \(timetableFileURL)")

			DispatchQueue.main.async {
				isSending = false
				errorMessage = "Timetable sent!"
				DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
					errorMessage = nil
				}
			}
		} catch {
			isSending = false
			errorMessage = "Error encoding timetable: \(error.localizedDescription)"
			print("[TimetableView] Error sending: \(error)")
		}
	}
}

#Preview {
	TimetableView()
}
