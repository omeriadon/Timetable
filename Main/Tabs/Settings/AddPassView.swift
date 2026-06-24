//
//  AddPassView.swift
//  Timetable
//
//  Created by Adon Omeri on 21/6/2026.
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

	@Environment(\.passManager) var passManager

	var body: some View {
		ZStack {
			if !PKAddPassesViewController.canAddPasses() {
				Text("Apple Wallet is not available on this device.")
					.foregroundStyle(.secondary)
					.transition(.blurReplace)
			} else {
				switch currentState {
					case .idle:
						ZStack {
							switch passManager.isSelfTimetableUpToDate() {
								case .notInWallet:
									Button {
										generatePassAsync()
									} label: {
										Label("Generate Apple Wallet Pass", systemImage: "wallet.pass")
											.foregroundStyle(.accent)
									}
								case .inWalletNotUpToDate:
									Button {
										generatePassAsync()
									} label: {
										Label("Generate Apple Wallet Pass", systemImage: "wallet.pass")
											.foregroundStyle(.accent)
										Text("Your pass in Wallet is not up to date")
											.foregroundStyle(.red)
									}
								case .inWalletUpToDate:
									Label("Your pass in Wallet is up to date", systemImage: "checkmark")
							}
						}
						.transition(.blurReplace)

					case .generating:
						HStack(spacing: 10) {
							ProgressView()
							Text("Generating Pass...")
						}
						.frame(maxWidth: .infinity, maxHeight: .infinity)
						.transition(.blurReplace)

					case .ready(let pass):
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

	private func generatePassAsync() {
		withAnimation(.easeInOut) {
			currentState = .generating
		}

		Task(priority: .userInitiated) {
			do {
				let url = try generatePass()
				let passData = try Data(contentsOf: url)
				let pass = try PKPass(data: passData)

				await MainActor.run {
					withAnimation(.easeInOut) {
						currentState = .ready(pass)
					}
				}
			} catch {
				print("[Wallet] Error generating pass: \(error)")
				await MainActor.run {
					withAnimation(.easeInOut) {
						currentState = .error
					}
				}
			}
		}
	}

	private func triggerResetTimer() {
		Task {
			try? await Task.sleep(for: .seconds(5))

			await MainActor.run {
				withAnimation(.easeInOut) {
					walletButtonID = UUID()
					currentState = .idle
				}
			}
		}
	}
}
