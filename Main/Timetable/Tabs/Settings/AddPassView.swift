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
					.padding(.leading)
					.transition(.blurReplace)
			} else if PKAddPassesViewController.canAddPasses() {
				if let url = try? generatePass(),
				   let passData = try? Data(contentsOf: url),
				   let pass = try? PKPass(data: passData)
				{
					AddPassToWalletButton([pass]) { added in
						hasBeenAdded = added
					}
					.addPassToWalletButtonStyle(.black)
					.transition(.blurReplace)
				} else {
					Text("Unable to generat a pass to add to Wallet.")
						.padding(.leading)
				}

			} else {
				Text("Apple Wallet is not available on this device.")
					.padding(.leading)
			}
		}
		.animation(.easeInOut, value: hasBeenAdded)
		.frame(height: 44)
	}
}
