import SwiftUI

struct AdministrationUserEditor: View {
	let target: AdministrationUserEditorTarget
	let didSave: (AdministrationUserResponse) -> Void
	let didDelete: (AdministrationUserResponse) -> Void
	let close: () -> Void

	@State private var service = AdministrationService.shared
	@State private var displayName: String
	@State private var email: String
	@State private var password = ""
	@State private var rawData = ""
	@State private var showsDeleteConfirmation = false
	@State private var expandedAccountDataNodeIDs: Set<String> = []
	@Environment(\.statusBadgeManager) private var badges

	init(
		target: AdministrationUserEditorTarget,
		didSave: @escaping (AdministrationUserResponse) -> Void,
		didDelete: @escaping (AdministrationUserResponse) -> Void,
		close: @escaping () -> Void
	) {
		self.target = target
		self.didSave = didSave
		self.didDelete = didDelete
		self.close = close
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
				#if os(iOS)
					.textInputAutocapitalization(.never)
				#endif
				#if os(iOS)
				.keyboardType(.emailAddress)
				#endif

				Section {
					SecureField(target.user == nil ? "Password" : "New Password", text: $password)
				} footer: {
					Text(target.user == nil ? "Passwords must contain at least eight characters." : "Leave blank to keep the current password.")
				}

				if target.user != nil {
					Section("Account Data") {
						if rawData.isEmpty {
							Text("Loading...")
						} else if let rows = AdministrationJSONFormatter.rootRows(from: rawData) {
							ForEach(rows) { row in
								AdministrationJSONNode(
									row: row,
									depth: 0,
									expandedNodeIDs: $expandedAccountDataNodeIDs
								)
							}
						} else {
							AdministrationJSONText(value: rawData)
						}
					}
				}
			}
			.appGroupedFormStyle()
			.appNavigationTitle(target.user == nil ? "New User" : "User", accent: true)
			.refreshable {
				await loadAccountData()
			}
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Close", systemImage: "xmark", role: .cancel) {
						close()
					}
					.labelStyle(.iconOnly)
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
					.labelStyle(.iconOnly)
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
			close()
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
			close()
		}
	}
}

private struct AdministrationJSONNode: View {
	let row: AdministrationJSONRow
	let depth: Int
	@Binding var expandedNodeIDs: Set<String>

	var body: some View {
		if let children = AdministrationJSONFormatter.childRows(from: row.value, parentID: row.id), !children.isEmpty {
			DisclosureGroup(isExpanded: expansion) {
				ForEach(children) { child in
					AdministrationJSONNode(row: child, depth: depth + 1, expandedNodeIDs: $expandedNodeIDs)
				}
			} label: {
				Text(row.label)
			}
			.listRowBackground(rowBackground)
		} else {
			LabeledContent(row.label) {
				AdministrationJSONFormattedValue(value: row.value)
			}
			.listRowBackground(rowBackground)
		}
	}

	private var rowBackground: Color? {
		switch depth {
			case 0: Color.white.opacity(0.08)
			case 1: Color.white.opacity(0.04)
			default: Color.white.opacity(0)
		}
	}

	private var expansion: Binding<Bool> {
		Binding(
			get: { expandedNodeIDs.contains(row.id) },
			set: { isExpanded in
				if isExpanded {
					expandedNodeIDs.insert(row.id)
				} else {
					expandedNodeIDs.remove(row.id)
				}
			}
		)
	}
}

private struct AdministrationJSONFormattedValue: View {
	let value: Any

	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			Text(AdministrationJSONFormatter.formattedDescription(value))
				.textSelection(.enabled)
				.fixedSize(horizontal: true, vertical: true)
				.frame(maxWidth: .infinity, alignment: .topLeading)
		}
		.scrollBounceBehavior(.basedOnSize, axes: .horizontal)
	}
}

private struct AdministrationJSONText: View {
	let value: String

	var body: some View {
		ScrollView(.horizontal) {
			Text(value)
				.textSelection(.enabled)
				.fixedSize(horizontal: false, vertical: true)
				.frame(maxWidth: .infinity, alignment: .topLeading)
		}
		.scrollBounceBehavior(.basedOnSize, axes: .horizontal)
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

private enum AdministrationJSONFormatter {
	static func rootRows(from json: String) -> [AdministrationJSONRow]? {
		guard let value = value(from: json) else {
			return nil
		}

		guard let rows = childRows(from: value, parentID: "root"), !rows.isEmpty else {
			return nil
		}

		return rows
	}

	static func childRows(from value: Any, parentID: String) -> [AdministrationJSONRow]? {
		switch value {
			case let dictionary as [String: Any]:
				dictionary.keys.sorted().map { key in
					AdministrationJSONRow(
						id: "\(parentID).dictionary-\(key)",
						label: key,
						value: dictionary[key] ?? NSNull()
					)
				}
			case let array as [Any]:
				array.enumerated().map { index, value in
					AdministrationJSONRow(
						id: "\(parentID).array-\(index)",
						label: "\(index + 1)",
						value: value
					)
				}
			default:
				nil
		}
	}

	static func value(from json: String) -> Any? {
		guard let data = json.data(using: .utf8) else {
			return nil
		}

		guard let object = try? JSONSerialization.jsonObject(with: data) else {
			return nil
		}

		return expandEmbeddedJSON(in: object)
	}

	static func primitiveDescription(_ value: Any) -> String {
		switch value {
			case let string as String:
				string
			case let number as NSNumber:
				number.stringValue
			case _ as NSNull:
				"null"
			default:
				String(describing: value)
		}
	}

	static func formattedDescription(_ value: Any) -> String {
		if let data = try? JSONSerialization.data(
			withJSONObject: value,
			options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]
		), let string = String(data: data, encoding: .utf8) {
			return string
		}

		return primitiveDescription(value)
	}

	private nonisolated static func expandEmbeddedJSON(in value: Any) -> Any {
		switch value {
			case let dictionary as [String: Any]:
				dictionary.mapValues(expandEmbeddedJSON(in:))
			case let array as [Any]:
				array.map(expandEmbeddedJSON(in:))
			case let string as String:
				expandJSON(from: string) ?? string
			default:
				value
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

private struct AdministrationJSONRow: Identifiable {
	let id: String
	let label: String
	let value: Any
}
