//
//   NameSheet.swift
//   Main
//
//   Created by Adon Omeri on 11/6/2026.
//

import Defaults
import SwiftUI

struct NameSheet: View {
	@Default(.userDisplayName) var userName

	@State private var name = ""

	var body: some View {
		NavigationStack {
			VStack(alignment: .center) {
				Image("Icon")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(maxWidth: 120)
					.padding(.bottom, 20)

				Text("What should we call you?")
					.padding(.bottom, 40)

				TextField("Display Name", text: $name)
					.textFieldStyle(.plain)
					.frame(width: 200)
					.padding(10)
					.glassEffect(.clear.interactive(), in: Capsule())
			}
			.scrollDismissesKeyboard(.immediately)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(role: .confirm) {
						userName = name
					}
					.disabled(name.isEmpty)
				}
			}
		}
	}
}

#Preview {
	NameSheet()
}
