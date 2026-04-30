//
//  ReceivedTimetableTranscriptView.swift
//  PMS Timetable Message Extension
//
//  Created by Adon Omeri on 29/4/2026.
//

import SwiftUI
import Messages
import Defaults

struct ReceivedTimetableTranscriptView: View {
	let messageUrl: URL?
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
					classesPreview(for: data)
					addButton
				}
				.padding(12)
				.background(Color(UIColor.systemBackground))
				.cornerRadius(12)
				.padding(8)
			} else if isLoading {
				ProgressView()
					.padding(8)
			} else {
				VStack(spacing: 4) {
					Text("Unable to load timetable")
						.font(.caption)
						.foregroundStyle(.secondary)
					Text(debugReason)
						.font(.caption2)
						.foregroundStyle(.tertiary)
						.multilineTextAlignment(.center)
				}
				.padding(8)
			}
		}
		.onAppear {
			loadTimetableData()
		}
		.onChange(of: messageUrl) { _, _ in
			loadTimetableData()
		}
	}
	
	private func headerSection(for data: ShareableTimetableData) -> some View {
		HStack {
			VStack(alignment: .leading, spacing: 4) {
				Text(data.sender)
					.font(.system(.headline, design: .default))
					.lineLimit(1)
				
				Text("\(data.classes.count) classes")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			Spacer()
			Image(systemName: hasAdded ? "checkmark.circle.fill" : "plus.circle")
				.font(.title2)
				.foregroundStyle(hasAdded ? .green : .blue)
		}
	}
	
	private func classesPreview(for data: ShareableTimetableData) -> some View {
		VStack(spacing: 8) {
			ForEach(data.classes.prefix(3), id: \.name) { cls in
				classRow(for: cls)
			}
			
			if data.classes.count > 3 {
				Text("+\(data.classes.count - 3) more")
					.font(.caption2)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, alignment: .center)
					.padding(.top, 4)
			}
		}
		.padding(.vertical, 8)
	}
	
	private func classRow(for cls: ShareableClass) -> some View {
		HStack(spacing: 8) {
			let color = parseColor(cls.color)
			color
				.frame(width: 12, height: 12)
				.cornerRadius(3)
			
			Text(cls.name)
				.font(.caption)
				.lineLimit(1)
			
			Spacer()
			
			Text(cls.symbol)
				.font(.caption2)
				.foregroundStyle(.secondary)
		}
	}
	
	private var addButton: some View {
		Button {
			if !hasAdded {
				onAdd()
				hasAdded = true
			}
		} label: {
			HStack {
				Image(systemName: hasAdded ? "checkmark" : "plus")
				Text(hasAdded ? "Added to Your Timetables" : "Add to My Timetables")
			}
			.font(.caption)
			.frame(maxWidth: .infinity)
			.padding(.vertical, 8)
			.background(hasAdded ? Color.green.opacity(0.2) : Color.blue.opacity(0.1))
			.foregroundStyle(hasAdded ? .green : .blue)
			.cornerRadius(6)
		}
		.disabled(hasAdded)
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
			debugReason = "No message URL provided by iMessage."
			isLoading = false
			return
		}
		
		let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
		guard let queryItems = components?.queryItems,
			  let dataParam = queryItems.first(where: { $0.name == "data" })?.value else {
			debugReason = "URL missing 'data' query item."
			isLoading = false
			return
		}
		
		do {
			timetableData = try ShareableTimetableData.fromBase64URL(dataParam)
			debugReason = ""
		} catch {
			debugReason = "Decode failed: \(error.localizedDescription)"
		}
		isLoading = false
	}
}

#Preview {
	ReceivedTimetableTranscriptView(messageUrl: nil) {
		print("Add tapped")
	}
}
