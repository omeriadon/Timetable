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
	@Environment(\.statusBadgeManager) private var badges

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
				if let user = target.user {
					Section("Authority") {
						LabeledContent("Role", value: user.authority.displayName)
					}
				}

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
			.refreshable {
				await loadAccountData()
			}
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
		.task { await loadAccountData() }
	}

	private func loadAccountData() async {
		guard let user = target.user else {
			return
		}

		do {
			rawData = try await service.userDetail(id: user.id).rawData
		} catch {
			badges.present(error: error, title: "Unable to load account data")
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
	private let object: [String: Any]

	init(json: String) {
		self.json = json
		object = AdministrationJSONFormatter.object(from: json) ?? [:]
	}

	var body: some View {
		if object.isEmpty {
			jsonText(json)
		} else {
			ForEach(object.keys.sorted(), id: \.self) { key in
				DisclosureGroup(key) {
					valueView(object[key])
				}
			}
		}
	}

	@ViewBuilder
	private func valueView(_ value: Any?) -> some View {
		switch value {
			case let dictionary as [String: Any]:
				ForEach(dictionary.keys.sorted(), id: \.self) { key in
					DisclosureGroup(key) {
						jsonText(AdministrationJSONFormatter.formatObject(dictionary[key] ?? NSNull()))
					}
				}
			case let array as [Any]:
				ForEach(Array(array.enumerated()), id: \.offset) { index, item in
					DisclosureGroup("Item \(index + 1)") {
						jsonText(AdministrationJSONFormatter.formatObject(item))
					}
				}
			default:
				jsonText(AdministrationJSONFormatter.formatObject(value ?? NSNull()))
		}
	}

	private func jsonText(_ value: String) -> some View {
		ScrollView([.horizontal, .vertical]) {
			Text(value)
				.font(.system(.caption, design: .monospaced))
				.textSelection(.enabled)
				.fixedSize(horizontal: true, vertical: true)
				.frame(maxWidth: .infinity, alignment: .topLeading)
		}
		.frame(maxHeight: 260)
	}
}

private enum AdministrationJSONFormatter {
	static func object(from json: String) -> [String: Any]? {
		guard let data = json.data(using: .utf8) else {
			return nil
		}
		return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
	}

	static func formatObject(_ object: Any) -> String {
		guard JSONSerialization.isValidJSONObject(object), let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]), let json = String(data: data, encoding: .utf8) else {
			return String(describing: object)
		}
		return format(json)
	}
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

	private nonisolated static func expandEmbeddedJSON(in object: Any) -> Any {
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

	private nonisolated static func expandJSON(from string: String) -> Any? {
		if let object = jsonObject(from: Data(string.utf8)) {
			return expandEmbeddedJSON(in: object)
		}

		guard let data = Data(base64Encoded: string), let object = jsonObject(from: data) else {
			return nil
		}

		return expandEmbeddedJSON(in: object)
	}

	private nonisolated static func jsonObject(from data: Data) -> Any? {
		guard let object = try? JSONSerialization.jsonObject(with: data), JSONSerialization.isValidJSONObject(object) else {
			return nil
		}

		return object
	}
}
