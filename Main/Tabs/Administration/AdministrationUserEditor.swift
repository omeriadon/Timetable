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
		ScrollView([.horizontal, .vertical]) {
			Text(AdministrationJSONFormatter.format(json))
				.font(.system(.caption, design: .monospaced))
				.textSelection(.enabled)
				.fixedSize(horizontal: true, vertical: true)
				.frame(maxWidth: .infinity, alignment: .topLeading)
		}
	}
}

private enum AdministrationJSONFormatter {
	static func format(_ json: String) -> String {
		guard
			let data = json.data(using: .utf8),
			let object = try? JSONSerialization.jsonObject(with: data)
		else {
			return json
		}

		guard JSONSerialization.isValidJSONObject(object) else {
			return json
		}

		let expandedObject = expandEmbeddedJSON(in: object)
		guard
			let formattedData = try? JSONSerialization.data(
				withJSONObject: expandedObject,
				options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
			),
			let formattedJSON = String(data: formattedData, encoding: .utf8)
		else {
			return json
		}

		return formattedJSON
	}

	nonisolated private static func expandEmbeddedJSON(in object: Any) -> Any {
		switch object {
			case let dictionary as [String: Any]:
				dictionary.mapValues(expandEmbeddedJSON(in:))

			case let array as [Any]:
				array.map(expandEmbeddedJSON(in:))

			case let string as String:
				expandJSON(from: string) ?? string

			default:
				object
		}
	}

	nonisolated private static func expandJSON(from string: String) -> Any? {
		if let object = jsonObject(from: Data(string.utf8)) {
			return expandEmbeddedJSON(in: object)
		}

		guard let data = Data(base64Encoded: string), let object = jsonObject(from: data) else {
			return nil
		}

		return expandEmbeddedJSON(in: object)
	}

	private static func jsonObject(from data: Data) -> Any? {
		guard let object = try? JSONSerialization.jsonObject(with: data), JSONSerialization.isValidJSONObject(object) else {
			return nil
		}

		return object
	}
}
