import SwiftUI

struct AdministrationSpecialBadgeEditor: View {
	let target: AdministrationSpecialBadgeEditorTarget
	let users: [AdministrationUserResponse]
	let save: (AdministrationSpecialBadgeRequest, UUID?, Set<UUID>) async throws -> AdministrationSpecialBadgeResponse
	let delete: (AdministrationSpecialBadgeResponse) async throws -> Void
	let close: () -> Void

	@Environment(\.statusBadgeManager) private var statusBadges
	@State private var symbol: String
	@State private var accessibilityLabel: String
	@State private var backgroundColor: Color
	@State private var symbolColor: Color
	@State private var selectedUserIDs: Set<UUID>
	@State private var isSaving = false
	@State private var showsDeleteConfirmation = false
	@State private var showsSymbolPicker = false

	init(
		target: AdministrationSpecialBadgeEditorTarget,
		users: [AdministrationUserResponse],
		save: @escaping (AdministrationSpecialBadgeRequest, UUID?, Set<UUID>) async throws -> AdministrationSpecialBadgeResponse,
		delete: @escaping (AdministrationSpecialBadgeResponse) async throws -> Void,
		close: @escaping () -> Void
	) {
		self.target = target
		self.users = users
		self.save = save
		self.delete = delete
		self.close = close
		let badge = target.badge
		_symbol = State(initialValue: badge?.symbol ?? "star.fill")
		_accessibilityLabel = State(initialValue: badge?.accessibilityLabel ?? "Badge")
		_backgroundColor = State(initialValue: badge?.backgroundColor?.swiftUIColor ?? .blue)
		_symbolColor = State(initialValue: badge?.symbolColor?.swiftUIColor ?? .white)
		_selectedUserIDs = State(initialValue: Set(badge?.assignedUserIDs ?? []))
	}

	private var isBuiltIn: Bool {
		target.badge.map { BuiltInProfileBadgeConfiguration.authority(for: $0.id) != nil } ?? false
	}

	var body: some View {
		NavigationStack {
			Form {
				Section("Badge") {
					Button {
						showsSymbolPicker = true
					} label: {
						Label("Symbol", systemImage: symbol)
					}
					TextField("Accessibility Label", text: $accessibilityLabel)
					ColorPicker("Background", selection: $backgroundColor, supportsOpacity: true)
					ColorPicker("Symbol", selection: $symbolColor, supportsOpacity: true)
				}
				.personalPaperListRow()

				if !isBuiltIn {
					Section {
						NavigationLink {
							AdministrationSpecialBadgeUsersView(
								users: users,
								selectedUserIDs: $selectedUserIDs
							)
						} label: {
							Label("Users (\(selectedUserIDs.count))", systemImage: "person.2")
						}
					} footer: {
						Text("Selected users receive this badge when the badge is saved. Deselect a user to remove it.")
					}
					.personalPaperListRow()
				}
			}
			.appGroupedFormStyle()
			.appNavigationTitle(target.badge == nil ? "New Badge" : "Edit Badge", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						close()
					}
				}

				ToolbarItem(placement: .confirmationAction) {
					Button(target.badge == nil ? "Create" : "Save", systemImage: target.badge == nil ? "plus" : "checkmark", role: .confirm) {
						Task {
							await saveBadge()
						}
					}
					.buttonStyle(.glassProminent)
					.disabled(symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || accessibilityLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
				}
			}
			.safeAreaBar(edge: .bottom) {
				if target.badge != nil, !isBuiltIn {
					Button("Delete Badge", systemImage: "trash", role: .destructive) {
						showsDeleteConfirmation = true
					}
					.buttonStyle(.glassProminent)
					.tint(.red)
				}
			}
		}
		.presentationDetents([.large])
		.sheet(isPresented: $showsSymbolPicker) {
			AdministrationEventSymbolPicker(symbol: $symbol)
				.appPaperPresentation()
		}
		.confirmationDialog("Delete Badge?", isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
			if let badge = target.badge {
				Button("Delete Badge", systemImage: "trash", role: .destructive) {
					Task {
						await deleteBadge(badge)
					}
				}
			}
		} message: {
			Text("This removes the badge from every assigned user.")
		}
	}

	private func saveBadge() async {
		isSaving = true
		defer {
			isSaving = false
		}

		do {
			_ = try await save(
				AdministrationSpecialBadgeRequest(
					symbol: symbol.trimmingCharacters(in: .whitespacesAndNewlines),
					backgroundColor: backgroundColor.toRGBA().normalized,
					symbolColor: symbolColor.toRGBA().normalized,
					priority: target.badge?.priority ?? 0,
					accessibilityLabel: accessibilityLabel.trimmingCharacters(in: .whitespacesAndNewlines)
				),
				target.badge?.id,
				selectedUserIDs
			)
			close()
		} catch {
			statusBadges.present(error: error, title: "Unable to save badge")
		}
	}

	private func deleteBadge(_ badge: AdministrationSpecialBadgeResponse) async {
		do {
			try await delete(badge)
			close()
		} catch {
			statusBadges.present(error: error, title: "Unable to delete badge")
		}
	}
}
