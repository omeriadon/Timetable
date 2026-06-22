//
//  AddPassView.swift
//  Timetable
//
//  Created by Adon Omeri on 21/6/2026.
//

import PassKit
import SwiftUI

struct AddPassView: View {
	@State private var hasBeenAdded = false

	var body: some View {
		ZStack {
			if hasBeenAdded {
				Text("Pass added to Apple Wallet.")
					.transition(.blurReplace)
			} else if PKAddPassesViewController.canAddPasses() {
				if let url = try? generatePass(timetableData: "Adon's Timetable Data Here"),
				   let passData = try? Data(contentsOf: url),
				   let pass = try? PKPass(data: passData)
				{
					AddPassToWalletButton([pass]) { added in
						hasBeenAdded = added
					}
					.frame(height: 44)
					.addPassToWalletButtonStyle(.black)
					.transition(.blurReplace)
				} else {
					Text("Unable to generat a pass to add to Wallet.")
				}

			} else {
				Text("Apple Wallet is not available on this device.")
			}
		}
		.animation(.easeInOut, value: hasBeenAdded)
	}
}
