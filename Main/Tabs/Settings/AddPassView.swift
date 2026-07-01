//
//   AddPassView.swift
//   Main
//
//   Created by Adon Omeri on 22/6/2026.
//

import PassKit
import SwiftUI

enum PassState: Equatable {
	case idle
	case generating
	case ready(PKPass)
	case added
	case error
}

struct AddPassView: View {
	@State private var currentState: PassState = .idle
	@State private var walletButtonID = UUID()
	@State private var passService = WalletPassService.shared
	@State private var resetTask: Task<Void, Never>?
	@Environment(\.statusBadgeManager) private var statusBadgeManager

	var body: some View {
		ZStack {
			if !PKAddPassesViewController.canAddPasses() {
				Text("Apple Wallet is not available on this device.")
					.foregroundStyle(.secondary)
					.transition(.blurReplace)
			} else {
				switch currentState {
					case .idle:
						Button("Generate Your Timetable Pass", systemImage: "wallet.pass", action: downloadPass)
							.foregroundStyle(.accent)
							.transition(.blurReplace)

					case .generating:
						HStack(spacing: 10) {
							ProgressView()
							Text("Generating Pass...")
						}
						.frame(maxWidth: .infinity, maxHeight: .infinity)
						.transition(.blurReplace)

					case let .ready(pass):
						AddPassToWalletButton([pass]) { added in
							if added {
								withAnimation(.easeInOut) {
									currentState = .added
								}
								triggerResetTimer()
							}
						}
						.addPassToWalletButtonStyle(.black)
						.id(walletButtonID)
						.clipShape(.containerRelative)
						.transition(.blurReplace)

					case .added:
						Text("Pass added to Apple Wallet.")

							.transition(.blurReplace)

					case .error:
						Text("Unable to generate a pass.")

							.foregroundColor(.red)
							.transition(.blurReplace)
				}
			}
		}
		.animation(.easeInOut, value: currentState)
	}

	private func downloadPass() {
		resetTask?.cancel()
		guard SessionStore.shared.isAuthenticated else {
			statusBadgeManager.addBadge(id: UUID(), title: "Sign in required", secondaryText: "Sign in to add your timetable to Wallet.", priority: 3, view: .warning)
			return
		}
		withAnimation(.easeInOut) {
			currentState = .generating
		}

		Task(priority: .userInitiated) {
			do {
				let pass = try await passService.downloadOwnerPass()
				withAnimation(.easeInOut) {
					currentState = .ready(pass)
				}
			} catch {
				PrintError("[Wallet] Error generating pass: \(error)")
				withAnimation(.easeInOut) {
					currentState = .error
				}
				statusBadgeManager.addBadge(id: UUID(), title: "Unable to generate your pass", secondaryText: error.localizedDescription, priority: 4, view: .error)
				triggerResetTimer()
			}
		}
	}

	private func triggerResetTimer() {
		resetTask?.cancel()
		resetTask = Task {
			try? await Task.sleep(for: .seconds(4))
			guard !Task.isCancelled else { return }

			withAnimation(.easeInOut) {
				walletButtonID = UUID()
				currentState = .idle
			}
		}
	}
}
