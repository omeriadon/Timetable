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
			VStack(spacing: 8) {
				TabView(selection: $selectedDay) {
					ForEach(0 ..< 5, id: \.self) { day in
						dayView(day)
							.tag(day)
					}
				}
				.tabViewStyle(.page(indexDisplayMode: .never))
				.frame(maxWidth: .infinity, maxHeight: .infinity)

				HStack(spacing: 4) {
					ForEach(0 ..< 5, id: \.self) { day in
						Text(dayLabels[day])
							.font(.system(size: 9, weight: .semibold, design: .monospaced))
							.foregroundStyle(day == selectedDay ? .white : .gray)
							.frame(maxWidth: .infinity)
					}
				}
				.padding(.horizontal, 4)
				.padding(.bottom, 4)
			}
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button {
						Task { await requestSyncFromPhoneAsync() }
					} label: {
						if isLoading {
							ProgressView()
								.scaleEffect(0.7)
								.transition(.blurReplace)
						} else if showSyncErrorIcon {
							Image(systemName: "exclamationmark.triangle.fill")
								.foregroundStyle(.yellow)
								.transition(.blurReplace)
						} else {
							Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
								.font(.system(size: 10, weight: .semibold, design: .monospaced))
								.transition(.blurReplace)
						}
					}
					.disabled(isLoading)
					.animation(.snappy, value: isLoading)
				}
			}
			.navigationBarTitleDisplayMode(.inline)
		}
		.environment(\.dynamicTypeSize, .xSmall)
		.monospaced()
		.onAppear {
			print("[Watch] ContentView appeared")
			syncStore.activateIfNeeded()
		}
		.onChange(of: syncStore.alertMessage) { _, newValue in
			guard let newValue else { return }
			print("[Watch] Surface error icon: \(newValue)")
			flashSyncErrorIcon()
			syncStore.alertMessage = nil
		}
	}

	@MainActor
	func requestSyncFromPhoneAsync() async {
		if isLoading { return }
		let startedAt = Date()
		withAnimation(.snappy) { isLoading = true }
		print("[Watch] Manual sync requested")

		syncStore.requestSyncFromPhone()

		let elapsed = Date().timeIntervalSince(startedAt)
		if elapsed < 0.35 {
			let remaining = UInt64((0.35 - elapsed) * 1_000_000_000)
			try? await Task.sleep(nanoseconds: remaining)
		}

		withAnimation(.snappy) { isLoading = false }
		print("[Watch] Manual sync finished")
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

	@ViewBuilder
	func sessionCell(_ day: Int, _ session: Int) -> some View {
		if session == 2 || session == 5 {
			HStack {
				Text(sessions[session])
					.font(.system(size: 8, weight: .semibold, design: .monospaced))
					.foregroundStyle(.secondary)
					.frame(width: 12)
				Spacer()
			}
			.frame(height: 8)
		} else if day == 2 && session == 7 || day == 4 && session == 7 {
			HStack {
				Text(sessions[session])
					.font(.system(size: 8, weight: .semibold, design: .monospaced))
					.foregroundStyle(.tertiary)
					.frame(width: 12)
				Spacer()
			}
			.frame(height: 12)
		} else if let c = classFor(day: day, session: session) {
			HStack(spacing: 3) {
				Image(systemName: c.symbol)
					.font(.system(size: 9, weight: .semibold))
					.foregroundStyle(.white)
					.frame(width: 14)

				VStack(alignment: .leading, spacing: 1) {
					Text(c.id)
						.font(.system(size: 8, weight: .semibold, design: .monospaced))
						.lineLimit(1)
					Text(sessions[session])
						.font(.system(size: 7, weight: .regular, design: .monospaced))
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding(.horizontal, 3)
			.padding(.vertical, 2)
			.background(c.colour.swiftUIColor.opacity(0.8), in: RoundedRectangle(cornerRadius: 4))
			.frame(height: 18)
		} else {
			HStack {
				Text(sessions[session])
					.font(.system(size: 8, weight: .semibold, design: .monospaced))
					.foregroundStyle(.tertiary)
					.frame(width: 12)
				Spacer()
			}
			.frame(height: 12)
		}
	}

	func classFor(day: Int, session: Int) -> Class? {
		syncStore.classes.first { c in
			c.slots.contains {
				$0.day == day && $0.session == session
			}
		}
	}
}

final class WatchTimetableSyncStore: NSObject, ObservableObject, WCSessionDelegate {
	@Published var classes: [Class] = []
	@Published var alertMessage: String?

	private var isActivated = false
	private let cacheKey = "watchTimetableCache"

	override init() {
		super.init()
		loadFromCache()
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

	func requestSyncFromPhone() {
		activateIfNeeded()
		let session = WCSession.default

		print("[Watch] requestSyncFromPhone()")
		print("[Watch] reachable: \(session.isReachable), activationState: \(session.activationState.rawValue)")

		guard session.activationState == .activated else {
			alertMessage = "WatchConnectivity is not active yet. Try again in a moment."
			print("[Watch] Cannot request sync: session not activated")
			return
		}

		guard session.isReachable else {
			alertMessage = "iPhone app is not reachable. Open it, then tap Sync again."
			print("[Watch] Cannot request sync: iPhone not reachable")
			return
		}

		session.sendMessage(["requestSync": true], replyHandler: { [weak self] reply in
			print("[Watch] Got reply from iPhone: keys=\(reply.keys.sorted())")
			self?.handleIncomingPayload(reply, source: "replyHandler")
		}, errorHandler: { [weak self] error in
			print("[Watch] sendMessage failed: \(error.localizedDescription)")
			DispatchQueue.main.async {
				self?.alertMessage = "Sync request failed: \(error.localizedDescription)"
			}
		})
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

	func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
		print("[Watch] didReceiveMessage")
		handleIncomingPayload(message, source: "didReceiveMessage")
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

	private func loadFromCache() {
		guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
			print("[Watch] No cached timetable found")
			return
		}

		do {
			let decoded = try JSONDecoder().decode([Class].self, from: data)
			classes = decoded
			print("[Watch] Loaded \(decoded.count) classes from local cache")
		} catch {
			print("[Watch] Failed to load cache: \(error.localizedDescription)")
		}
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

// MARK: - Models

struct Class: Hashable, Codable, Identifiable {
	var id: String
	var symbol: String
	var colour: RGBAColor
	var slots: [Slot]
}

struct Slot: Hashable, Codable {
	let day: Int
	let session: Int

	init(_ day: Int, _ session: Int) {
		self.day = day
		self.session = session
	}
}

struct RGBAColor: Codable, Hashable {
	var r: Double
	var g: Double
	var b: Double
	var a: Double

	var swiftUIColor: Color {
		Color(red: r, green: g, blue: b, opacity: a)
	}
}

#Preview {
	ContentView()
}
