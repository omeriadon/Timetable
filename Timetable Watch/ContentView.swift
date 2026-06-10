//
//  ContentView.swift
//  Timetable Watch Watch App
//
//  Created by Adon Omeri on 26/4/2026.
//

import Combine
import Defaults
import SwiftUI
import WatchConnectivity
import WidgetKit

struct ContentView: View {
	@StateObject private var syncStore = WatchTimetableSyncStore()
	@State private var selectedDay = 0
	@State private var isLoading = false
	@State private var showSyncErrorIcon = false
	@State private var displayModeConfirmation: String?

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: syncStore.classes)

		NavigationStack {
			VStack {
				HStack {
					Text("Timetable")
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

						ForEach(Array(TimetableLayout.sessions.enumerated()), id: \.offset) { index, session in
							if TimetableLayout.isBreakSession(index: index) {
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

					mainContent(classLookup: classLookup)
				}
				Spacer()
			}
		}
		.environment(\.dynamicTypeSize, .xSmall)
		.monospaced()
		.overlay(alignment: .center) {
			if let mode = displayModeConfirmation {
				VStack(spacing: 8) {
					Label(mode, systemImage: mode == "Symbols" ? "square.grid.2x2" : "text.alignleft")
						.font(.headline)
				}
				.padding(.horizontal, 24)
				.padding(.vertical, 14)
				.glassEffect(
					.regular.tint(.blue),
					in: RoundedRectangle(cornerRadius: 12)
				)
				.transition(.opacity.combined(with: .scale(scale: 0.9)))
			}
		}
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
		.onChange(of: syncStore.displayMode) { _, newMode in
			displayModeConfirmation = newMode == .symbolsOnly ? "Symbols" : "Text"
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
				displayModeConfirmation = nil
			}
		}
	}

	func mainContent(classLookup: [Slot: Class]) -> some View {
		ForEach(0 ..< 5) { day in
			VStack(spacing: 2) {
				Text(TimetableLayout.shortDayLabels[day])
					.font(.footnote.scaled(by: 0.8))
					.frame(height: 15)
				ForEach(0 ..< 8) { session in
					sessionCell(day, session, classLookup: classLookup)
				}
			}
		}
	}

	func sessionCell(_ day: Int, _ session: Int, classLookup: [Slot: Class]) -> some View {
		Group {
			if TimetableLayout.isBreakSession(index: session) {
				// recess and lunch
				rectangle(.gray.opacity(0.25), true)
					.frame(height: 2)
			} else {
				// early finish days
				if TimetableLayout.isUnavailable(day: day, session: session) {
					rectangle(.clear, true)
						.frame(height: 25)

				} else {
					// actual session
					if let c = classLookup[Slot(day, session)] {
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
		.foregroundStyle(.white)
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
		let classLookup = TimetableLayout.classLookup(for: syncStore.classes)

		return ScrollView(.vertical, showsIndicators: false) {
			VStack(spacing: 4) {
				ForEach(0 ..< 8, id: \.self) { session in
					sessionCell(day, session, classLookup: classLookup)
				}
			}
			.padding(.horizontal, 4)
			.padding(.vertical, 6)
		}
	}
}

final class WatchTimetableSyncStore: NSObject, ObservableObject, WCSessionDelegate {
	@Published var classes: [Class] = []
	@Published var displayMode: DisplayMode = .symbolsOnly
	@Published var alertMessage: String?

	private var isActivated = false

	override init() {
		super.init()
		classes = Defaults[.timetable]
		displayMode = Defaults[.displayMode]
		print("[Watch] Init complete, loaded from Defaults: \(classes.count) classes")
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

	func session(_: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
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

	func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
		print("[Watch] didReceiveApplicationContext")
		handleIncomingPayload(applicationContext, source: "applicationContext")
	}

	func session(_: WCSession, didReceiveMessage message: [String: Any]) {
		print("[Watch] didReceiveMessage")
		handleIncomingPayload(message, source: "message")
	}

	func session(_: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
		print("[Watch] didReceiveMessage with replyHandler")
		handleIncomingPayload(message, source: "message")
		replyHandler(["status": "ok"])
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

			var mode = DisplayMode.symbolsOnly
			if let modeData = payload["displayMode"] as? Data {
				do {
					mode = try JSONDecoder().decode(DisplayMode.self, from: modeData)
					print("[Watch] Decoded displayMode: \(mode.rawValue)")
				} catch {
					print("[Watch] Failed to decode displayMode: \(error)")
				}
			}

			DispatchQueue.main.async {
				let currentClasses = Defaults[.timetable]
				let currentMode = Defaults[.displayMode]
				let didChangePayload = currentClasses != decoded || currentMode != mode

				self.classes = decoded
				self.displayMode = mode

				guard didChangePayload else {
					print("[Watch] Payload unchanged; skipping Defaults write and widget reload")
					return
				}

				Defaults[.timetable] = decoded
				Defaults[.displayMode] = mode
				print("[Watch] Saved to Defaults - displayMode: \(mode.rawValue)")
				WidgetCenter.shared.reloadTimelines(ofKind: "Timetable_Watch_Widgets")
				print("[Watch] ✓ Reloaded widget timelines")
			}
		} catch {
			print("[Watch] Failed to decode payload from \(source): \(error.localizedDescription)")
			DispatchQueue.main.async {
				self.alertMessage = "Decode failed: \(error.localizedDescription)"
			}
		}
	}
}

#Preview {
	ContentView()
}
