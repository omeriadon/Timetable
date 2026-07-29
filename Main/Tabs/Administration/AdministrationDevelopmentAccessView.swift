import SwiftUI

struct AdministrationDevelopmentAccessView: View {
	@State private var service = AdministrationService.shared
	@State private var controlToken = ""
	@State private var developmentAccessOnly: Bool?
	@State private var pendingDevelopmentAccessOnly: Bool?
	@State private var isUpdating = false

	var body: some View {
		Form {
			Section("Server Control Token") {
				SecureField("Control Token", text: $controlToken)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()

				Button("Load Server Mode", systemImage: "arrow.clockwise") {
					Task {
						await load()
					}
				}
				.disabled(controlToken.isEmpty || isUpdating)
			}

			Section {
				Toggle(
					"Restrict Server to Owners",
					isOn: Binding(
						get: { developmentAccessOnly ?? false },
						set: { pendingDevelopmentAccessOnly = $0 }
					)
				)
				.disabled(developmentAccessOnly == nil || controlToken.isEmpty || isUpdating)
			} header: {
				Text("Development Access")
			} footer: {
				Text("When enabled, only the two permanent owner accounts can use the server. Existing sessions remain intact but receive an access error.")
			}
		}
		.scrollEdgeEffect()
		.appNavigationTitle("Debug Testing", accent: true)
		.refreshable {
			guard !controlToken.isEmpty else {
				return
			}

			await load()
		}
		.confirmationDialog(
			pendingDevelopmentAccessOnly == true ? "Restrict Server to Owners?" : "Restore Normal Server Access?",
			isPresented: Binding(
				get: { pendingDevelopmentAccessOnly != nil },
				set: { isPresented in
					if !isPresented {
						pendingDevelopmentAccessOnly = nil
					}
				}
			),
			titleVisibility: .visible
		) {
			if let pendingDevelopmentAccessOnly {
				Button(
					pendingDevelopmentAccessOnly ? "Restrict to Owners" : "Restore Normal Access",
					systemImage: pendingDevelopmentAccessOnly ? "lock.fill" : "lock.open",
					role: .confirm
				) {
					update(developmentAccessOnly: pendingDevelopmentAccessOnly)
				}
			}
		} message: {
			Text(
				pendingDevelopmentAccessOnly == true
					? "All non-owner accounts will receive an access error until normal access is restored."
					: "All accounts will be able to use the server again."
			)
		}
	}

	private func load() async {
		isUpdating = true
		defer {
			isUpdating = false
		}

		guard let response = try? await service.serverAccessMode(controlToken: controlToken) else {
			return
		}

		developmentAccessOnly = response.developmentAccessOnly
	}

	private func update(developmentAccessOnly: Bool) {
		isUpdating = true
		Task {
			defer {
				isUpdating = false
				pendingDevelopmentAccessOnly = nil
			}

			guard let response = try? await service.updateServerAccessMode(
				developmentAccessOnly: developmentAccessOnly,
				controlToken: controlToken
			) else {
				return
			}

			self.developmentAccessOnly = response.developmentAccessOnly
		}
	}
}
