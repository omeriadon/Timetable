//
//  ContentView.swift
//  PMS Timetable Watch Watch App
//
//  Created by Adon Omeri on 26/4/2026.
//

import Combine
import SwiftUI
import WatchConnectivity

struct ContentView: View {
	@StateObject private var syncStore = WatchTimetableSyncStore()
	@State private var selectedDay = 0
	@State private var isLoading = false
	@State private var showSyncErrorIcon = false

	private let sessions = ["1", "2", "R", "3", "4", "L", "5", "6"]
	private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri"]

	var body: some View {
		NavigationStack {
			VStack {
				HStack {
					Text("PMS Timetable")
						.padding(.leading, 30)
						.fontWeight(.black)
						.fontWidth(.expanded)
						.font(.footnote)
					Spacer()
				}
				HStack(spacing: 2) {
					VStack(spacing: 2) {
						Text("")
							.frame(height: 15)
							.font(.footnote)

						ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
							if index == 2 || index == 5 {
								Text(session)
									.font(.footnote.scaled(by: 0.7))
									.foregroundStyle(.secondary)
									.frame(height: 2)
							} else {
								Text(session)
									.font(.footnote)
									.frame(height: 25)
							}
						}
					}
					.frame(width: 15)

					mainContent
				}
				Spacer()
			}
		}
		.environment(\.dynamicTypeSize, .xSmall)
		.monospaced()
		.onAppear {
			print("[Watch] ContentView appeared")
			syncStore.activateIfNeeded()
			// Pre-build lookup table in background so first click doesn't hang
			Task {
				if !syncStore.classes.isEmpty {
					syncStore.buildLookupTable(syncStore.classes)
					print("[Watch] Pre-built lookup table on appear")
				}
			}
		}
		.onChange(of: syncStore.alertMessage) { _, newValue in
			guard let newValue else { return }
			print("[Watch] Surface error icon: \(newValue)")
			flashSyncErrorIcon()
			syncStore.alertMessage = nil
		}
	}

	var mainContent: some View {
		ForEach(0 ..< 5) { day in
			VStack(spacing: 2) {
				Text(["Mon", "Tue", "Wed", "Thu", "Fri"][day])
					.font(.footnote.scaled(by: 0.8))
					.frame(height: 15)
				ForEach(0 ..< 8) { session in
					sessionCell(day, session)
				}
			}
		}
	}

	@ViewBuilder
	func sessionCell(_ day: Int, _ session: Int) -> some View {
		if session == 2 || session == 5 {
			// recess and lunch
			rectangle(.gray.opacity(0.25), true)
				.frame(height: 2)
		} else {
			// early finish days
			if day == 2 && session == 7 || day == 4 && session == 7 {
				rectangle(.clear, true)
					.frame(height: 25)

			} else {
				// actual sessino
				if let c = classFor(day: day, session: session) {
					rectangle(
						c.colour.swiftUIColor.opacity(0.8)
					) {
						Image(systemName: c.symbol)
							.imageScale(.small)
							.font(.footnote.scaled(by: 0.7))
						Spacer(minLength: 0)
						Text(c.id)
							.lineLimit(2)
							.fixedSize(horizontal: false, vertical: true)
							.font(.footnote.scaled(by: 0.5))
					}
					.frame(height: 25)

				} else {
					// empty periods
					RoundedRectangle(cornerRadius: 5)
						.fill(.white.opacity(0.05))
						.frame(height: 25)
				}
			}
		}
	}

	@MainActor
	func flashSyncErrorIcon() {
		withAnimation(.snappy) { showSyncErrorIcon = true }
		Task {
			try? await Task.sleep(nanoseconds: 1_000_000_000)
			await MainActor.run {
				withAnimation(.snappy) { showSyncErrorIcon = false }
			}
		}
	}

	func dayView(_ day: Int) -> some View {
		ScrollView(.vertical, showsIndicators: false) {
			VStack(spacing: 4) {
				ForEach(0 ..< 8, id: \.self) { session in
					sessionCell(day, session)
				}
			}
			.padding(.horizontal, 4)
			.padding(.vertical, 6)
		}
	}

	func classFor(day: Int, session: Int) -> Class? {
		let key = "\(day)-\(session)"
		return syncStore.classes.isEmpty ? nil : syncStore.classLookup[key]
	}
}

final class WatchTimetableSyncStore: NSObject, ObservableObject, WCSessionDelegate {
	@Published var classes: [Class] = []
	@Published var alertMessage: String?
	
	var classLookup: [String: Class] = [:]

	private var isActivated = false
	private let cacheKey = "watchTimetableCache"

	override init() {
		super.init()
		// Load from cache synchronously for initial state
		// Dictionary will be built on first appear to avoid blocking UI
		classes = loadClassesFromCache()
	}

	func activateIfNeeded() {
		guard WCSession.isSupported() else {
			print("[Watch] WCSession not supported")
			return
		}
		guard !isActivated else { return }

		let session = WCSession.default
		session.delegate = self
		session.activate()
		isActivated = true
		print("[Watch] WCSession activate() called")
	}

	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("[Watch] WC activation completed with state: \(activationState.rawValue)")
		if let error {
			print("[Watch] WC activation error: \(error.localizedDescription)")
			DispatchQueue.main.async {
				self.alertMessage = "WatchConnectivity activation failed: \(error.localizedDescription)"
			}
		}
	}

	func sessionReachabilityDidChange(_ session: WCSession) {
		print("[Watch] Reachability changed: \(session.isReachable)")
	}

	func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
		print("[Watch] didReceiveApplicationContext")
		handleIncomingPayload(applicationContext, source: "applicationContext")
	}

	private func handleIncomingPayload(_ payload: [String: Any], source: String) {
		if let payloadError = payload["error"] as? String {
			print("[Watch] Payload error from \(source): \(payloadError)")
			DispatchQueue.main.async {
				self.alertMessage = payloadError
			}
			return
		}

		guard let data = payload["timetableData"] as? Data else {
			print("[Watch] No timetableData found in \(source)")
			return
		}

		do {
			let decoded = try JSONDecoder().decode([Class].self, from: data)
			print("[Watch] Decoded \(decoded.count) classes from \(source)")

			DispatchQueue.main.async {
				self.classes = decoded
				self.buildLookupTable(decoded)
				self.saveToCache(decoded)
				print("[Watch] ✓ UI updated with \(decoded.count) classes")
			}
		} catch {
			print("[Watch] Failed to decode payload from \(source): \(error.localizedDescription)")
			DispatchQueue.main.async {
				self.alertMessage = "Decode failed: \(error.localizedDescription)"
			}
		}
	}

	private func loadClassesFromCache() -> [Class] {
		guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
			print("[Watch] No cached timetable found")
			return []
		}

		do {
			let decoded = try JSONDecoder().decode([Class].self, from: data)
			print("[Watch] Loaded \(decoded.count) classes from local cache")
			return decoded
		} catch {
			print("[Watch] Failed to load cache: \(error.localizedDescription)")
			return []
		}
	}

	private func loadFromCache() {
		guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
			print("[Watch] No cached timetable found")
			return
		}

		do {
			let decoded = try JSONDecoder().decode([Class].self, from: data)
			classes = decoded
			buildLookupTable(decoded)
			print("[Watch] Loaded \(decoded.count) classes from local cache")
		} catch {
			print("[Watch] Failed to load cache: \(error.localizedDescription)")
		}
	}
	
	func buildLookupTable(_ classesArray: [Class]) {
		var lookup: [String: Class] = [:]
		for c in classesArray {
			for slot in c.slots {
				let key = "\(slot.day)-\(slot.session)"
				lookup[key] = c
			}
		}
		classLookup = lookup
		print("[Watch] Built lookup table with \(lookup.count) entries")
	}

	private func saveToCache(_ classes: [Class]) {
		do {
			let data = try JSONEncoder().encode(classes)
			UserDefaults.standard.set(data, forKey: cacheKey)
			print("[Watch] Cached timetable locally: \(data.count) bytes")
		} catch {
			print("[Watch] Failed to cache timetable: \(error.localizedDescription)")
		}
	}
}

struct rectangle<Content: View>: View {
	let fill: Color
	let isBreak: Bool
	let content: Content

	init(
		_ fill: Color,
		_ isBreak: Bool = false,
		@ViewBuilder content: () -> Content
	) {
		self.fill = fill
		self.isBreak = isBreak
		self.content = content()
	}

	init(_ fill: Color, _ isBreak: Bool = false) where Content == EmptyView {
		self.fill = fill
		self.isBreak = isBreak
		self.content = EmptyView()
	}

	var body: some View {
		VStack(alignment: .leading) {
			content
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		}
		.padding(2)
		.glassEffect(
			!isBreak ? .clear.tint(fill).interactive() : .identity,
			in: RoundedRectangle(cornerRadius: isBreak ? 1 : 4)
		)
	}
}

#Preview {
	ContentView()
}
