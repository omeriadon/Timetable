//
//  ReceivedTimetableTranscriptView.swift
//  Timetable Message Extension
//
//  Created by Adon Omeri on 29/4/2026.
//

import Defaults
import Messages
import SwiftUI

struct ReceivedTimetableTranscriptView: View {
	let messageUrl: URL?
	let fallbackPayload: String?
	let onAdd: () -> Void

	@State private var timetableData: ShareableTimetableData?
	@State private var hasAdded = false
	@State private var isLoading = true
	@State private var debugReason = "Unknown error"

	var body: some View {
		ZStack {
			if let data = timetableData {
				VStack(spacing: 12) {
					addButton

					classesPreview(for: data)
				}
			} else if isLoading {
				ProgressView()
			} else {
				ContentUnavailableView(
					"Unable to load timetable",
					systemImage: "exclamationmark.triangle",
					description: Text(debugReason)
				)
			}
		}
		.onAppear {
			loadTimetableData()
		}
		.onChange(of: messageUrl) {
			loadTimetableData()
		}
		.padding()
		.monospaced()
	}

	private func classesPreview(for data: ShareableTimetableData) -> some View {
		TimetableGridPreview(
			classes: data.decodedClasses(),
			showsTitle: true,
			rowScale: 0.78,
			showBackground: false
		)
	}

	private var addButton: some View {
		Button {
			if !hasAdded {
				onAdd()
				hasAdded = true
			}
		} label: {
			Label(hasAdded ? "Opening Timetable" : "Open in Timetable", systemImage: hasAdded ? "checkmark" : "plus")
		}
		.tint(.blue)
		.buttonStyle(.glassProminent)
		.disabled(hasAdded)
		.buttonBorderShape(.capsule)
		.buttonSizing(.flexible)
		.controlSize(.large)
	}

	private func loadTimetableData() {
		isLoading = true
		timetableData = nil

		guard let url = messageUrl else {
			loadTimetableData(fromPayload: fallbackPayload, missingPayloadReason: "No message URL or metadata provided by iMessage.")
			return
		}

		let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
		let dataParam = components?.fragment ?? components?.queryItems?.first(where: { $0.name == "data" })?.value ?? fallbackPayload
		guard let dataParam else {
			debugReason = "URL missing timetable payload."
			isLoading = false
			return
		}

		loadTimetableData(fromPayload: dataParam, missingPayloadReason: "URL missing timetable payload.")
	}

	private func loadTimetableData(fromPayload payload: String?, missingPayloadReason: String) {
		guard let payload else {
			debugReason = missingPayloadReason
			isLoading = false
			return
		}

		do {
			timetableData = try ShareableTimetableData.fromBase64URL(payload)
			debugReason = ""
		} catch {
			debugReason = "Decode failed: \(error.localizedDescription)"
		}
		isLoading = false
	}
}

#Preview {
	ReceivedTimetableTranscriptView(messageUrl: nil, fallbackPayload: nil) {
		print("Add tapped")
	}
}
