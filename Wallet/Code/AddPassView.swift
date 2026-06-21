//
//  AddPassView.swift
//  Timetable
//
//  Created by Adon Omeri on 21/6/2026.
//

import PassKit
import SwiftUI

struct AddPassView: View {
	@State private var isProcessing = false
	@State private var alertMessage = ""
	@State private var showAlert = false

	var body: some View {
		VStack(spacing: 20) {
			Button(action: {
				addPassToWallet()
			}) {
				HStack {
					if isProcessing {
						ProgressView()
							.padding(.trailing, 5)
					}
					Text("Add to Apple Wallet")
				}
			}
			.buttonStyle(.borderedProminent)
			.disabled(isProcessing)
		}
		.alert(isPresented: $showAlert) {
			Alert(title: Text("Wallet Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
		}
	}

	private func addPassToWallet() {
		isProcessing = true

		// 1. Ensure the device is capable of processing passes
		guard PKAddPassesViewController.canAddPasses() else {
			alertMessage = "Apple Wallet is not available on this device."
			showAlert = true
			isProcessing = false
			return
		}

		// Run on a background queue to keep your SwiftUI interface buttery smooth
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				// 2. Generate the .pkpass file via your OpenSSL engine
				let url = try generatePass(timetableData: "Adon's Timetable Data Here")
				let passData = try Data(contentsOf: url)
				let pass = try PKPass(data: passData)

				// 3. Interface directly with the PassKit secure database
				let passLibrary = PKPassLibrary()

				DispatchQueue.main.async {
					passLibrary.addPasses([pass]) { status in
						isProcessing = false

						switch status {
							case .didAddPasses:
								alertMessage = "🎉 Success! Your timetable has been added to Apple Wallet."
								showAlert = true
							case .didCancelAddPasses:
								print("User cancelled the transaction.")
							case .shouldReviewPasses:
								alertMessage = "Please open the Wallet App to finish reviewing this pass."
								showAlert = true
							@unknown default:
								break
						}
					}
				}
			} catch {
				DispatchQueue.main.async {
					isProcessing = false
					alertMessage = "Failed to generate pass: \(error.localizedDescription)"
					showAlert = true
					print("Error: \(error)")
				}
			}
		}
	}
}
