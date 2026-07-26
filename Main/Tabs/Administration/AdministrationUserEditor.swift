import SwiftUI

struct AdministrationUserEditor: View {
	let target: AdministrationUserEditorTarget
	let didSave: (AdministrationUserResponse) -> Void
	let didDelete: (AdministrationUserResponse) -> Void

	@Environment(\.dismiss) private var dismiss
	@State private var service = AdministrationService.shared
	@State private var displayName: String
	@State private var email: String
	@State private var password = ""
	@State private var rawData = ""
	@State private var showsDeleteConfirmation = false

	init(
		target: AdministrationUserEditorTarget,
		didSave: @escaping (AdministrationUserResponse) -> Void,
		didDelete: @escaping (AdministrationUserResponse) -> Void
	) {
		self.target = target
		self.didSave = didSave
		self.didDelete = didDelete
		_displayName = State(initialValue: target.user?.displayName ?? "")
		_email = State(initialValue: target.user?.email ?? "")
	}

	var body: some View {
		NavigationStack {
			Form {
				TextField("Name", text: $displayName)
				TextField("Email", text: $email)
					.textInputAutocapitalization(.never)
					.keyboardType(.emailAddress)

				Section {
					SecureField(target.user == nil ? "Password" : "New Password", text: $password)
				} footer: {
					Text(target.user == nil ? "Passwords must contain at least eight characters." : "Leave blank to keep the current password.")
				}

				if target.user != nil {
					Section("Account Data") {
						if rawData.isEmpty {
							Text("Loading...")
						} else {
							AdministrationJSONRenderer(json: rawData)
						}
					}
				}
			}
			.appNavigationTitle(target.user == nil ? "New User" : "User", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					}
				}

				ToolbarItem(placement: .confirmationAction) {
					Button(target.user == nil ? "Create" : "Save", systemImage: target.user == nil ? "plus" : "checkmark", role: .confirm) {
						save()
					}
					.disabled(
						displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
							|| email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
							|| (target.user == nil && password.count < 8)
					)
					.buttonStyle(.glassProminent)
				}
			}
			.safeAreaBar(edge: .bottom) {
				if target.user != nil {
					Button("Delete Account", systemImage: "trash", role: .destructive) {
						showsDeleteConfirmation = true
					}
					.buttonStyle(.glassProminent)
					.tint(.red)
				}
			}
		}
		.confirmationDialog("Delete Account?", isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
			if let user = target.user {
				Button("Delete Account", systemImage: "trash", role: .destructive) {
					delete(user)
				}
			}
		} message: {
			Text("This permanently deletes the account and its associated records.")
		}
		.task {
			guard let user = target.user else {
				return
			}

			rawData = await (try? service.userDetail(id: user.id).rawData) ?? "Unable to load account data."
		}
	}

	private func save() {
		Task {
			let savedUser: AdministrationUserResponse?
			if let user = target.user {
				let request = AdministrationUserUpdateRequest(
					displayName: displayName,
					email: email,
					password: password.isEmpty ? nil : password
				)
				savedUser = try? await service.updateUser(id: user.id, request: request)
			} else {
				let request = AdministrationUserCreateRequest(
					displayName: displayName,
					email: email,
					password: password
				)
				savedUser = try? await service.createUser(request: request)
			}

			guard let savedUser else {
				return
			}

			didSave(savedUser)
			dismiss()
		}
	}

	private func delete(_ user: AdministrationUserResponse) {
		Task {
			do {
				try await service.deleteUser(id: user.id)
			} catch {
				return
			}

			didDelete(user)
			dismiss()
		}
	}
}

private struct AdministrationJSONRenderer: View {
	let json: String

	var body: some View {
		ScrollView(.horizontal) {
			Text(json)
				.font(.system(.caption, design: .monospaced))
				.textSelection(.enabled)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}
