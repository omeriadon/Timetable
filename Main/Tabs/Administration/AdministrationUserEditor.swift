import SwiftUI

struct AdministrationUserEditor: View {
	let user: AdministrationUserResponse
	let didSave: (AdministrationUserResponse) -> Void

	@Environment(\.dismiss) private var dismiss
	@State private var service = AdministrationService.shared
	@State private var displayName: String
	@State private var email: String
	@State private var password = ""

	init(
		user: AdministrationUserResponse,
		didSave: @escaping (AdministrationUserResponse) -> Void
	) {
		self.user = user
		self.didSave = didSave
		_displayName = State(initialValue: user.displayName)
		_email = State(initialValue: user.email ?? "")
	}

	var body: some View {
		NavigationStack {
			Form {
				TextField("Name", text: $displayName)
				TextField("Email", text: $email)
					.textInputAutocapitalization(.never)
					.keyboardType(.emailAddress)

				Section {
					SecureField("New Password", text: $password)
				} footer: {
					Text("Leave blank to keep the current password.")
				}
			}
			.appNavigationTitle("User")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					}
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Save", systemImage: "checkmark", role: .confirm) {
						save()
					}
					.disabled(
						displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
							|| email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
					)
					.buttonStyle(.glassProminent)
				}
			}
		}
		.presentationDetents([.fraction(0.6)])
	}

	private func save() {
		Task {
			let request = AdministrationUserUpdateRequest(
				displayName: displayName,
				email: email,
				password: password.isEmpty ? nil : password
			)

			guard let updatedUser = try? await service.updateUser(id: user.id, request: request) else {
				return
			}

			didSave(updatedUser)
			dismiss()
		}
	}
}
