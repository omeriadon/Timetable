//
//  ReceivedTimetableTranscriptView.swift
//  PMS Timetable Message Extension
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
		Group {
			if let data = timetableData {
				VStack(spacing: 12) {
					headerSection(for: data)
						.padding()
					classesPreview(for: data)
					addButton
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

	private func headerSection(for data: ShareableTimetableData) -> some View {
		HStack(spacing: 15) {
			Text(data.sender)
				.font(.headline)
				.lineLimit(1)

			Text("\(data.classes.count) classes")
				.foregroundStyle(.tertiary)

			Spacer()
		}
	}

	private func classesPreview(for data: ShareableTimetableData) -> some View {
		List {
			ForEach(data.classes, id: \.name) { cls in
				HStack(spacing: 12) {
					Image(systemName: cls.symbol)

					Text(cls.name)

					Spacer()

					Text("\(cls.slots.count) slot\(cls.slots.count == 1 ? "" : "s")")
				}
				.listRowSeparator(.hidden)
				.listRowBackground(parseColor(cls.color).opacity(0.5))
			}
		}
		.scrollBounceBehavior(.basedOnSize)
		.scrollContentBackground(.hidden)
	}

	private var addButton: some View {
		Button {
			if !hasAdded {
				onAdd()
				hasAdded = true
			}
		} label: {
			Label(hasAdded ? "Opening PMS Timetable" : "Open in PMS Timetable", systemImage: hasAdded ? "checkmark" : "plus")
		}
		.tint(.blue)
		.buttonStyle(.glassProminent)
		.disabled(hasAdded)
		.buttonBorderShape(.capsule)
		.buttonSizing(.flexible)
		.controlSize(.large)
	}

	private func parseColor(_ hexString: String) -> Color {
		let hex = hexString.dropFirst()
		let r = Double(UInt8(hex.prefix(2), radix: 16) ?? 0) / 255
		let g = Double(UInt8(hex.dropFirst(2).prefix(2), radix: 16) ?? 0) / 255
		let b = Double(UInt8(hex.dropFirst(4).prefix(2), radix: 16) ?? 0) / 255
		return Color(red: r, green: g, blue: b)
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
