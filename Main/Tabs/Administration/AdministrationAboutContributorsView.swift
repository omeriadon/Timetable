import SwiftUI

struct AdministrationAboutContributorsView: View {
	@State private var service = AdministrationService.shared
	@State private var contributors: [AboutContributorResponse] = []
	@State private var editor: AdministrationAboutContributorEditorTarget?
	@State private var pendingDeletion: AboutContributorResponse?
	@Namespace private var sheetNamespace
	@Environment(\.statusBadgeManager) private var statusBadges

	var body: some View {
		List {
			Section {
				ForEach(contributors) { contributor in
					AdministrationAboutContributorRow(
						contributor: contributor,
						isFirst: contributor.id == contributors.first?.id,
						isLast: contributor.id == contributors.last?.id,
						isDisabled: editor != nil,
						namespace: sheetNamespace,
						move: { direction in
							move(contributor, direction: direction)
						},
						edit: {
							editor = .edit(contributor)
						},
						remove: {
							pendingDeletion = contributor
						}
					)
				}
			} header: {
				Text("Contributors")
			} footer: {
				Text("These names appear in the About section of the app and website.")
			}
			.glurListRowBackground()
		}
		.appPaperBackground()
		.appNavigationTitle("About Contributors", accent: true)
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button("Add Contributor", systemImage: "plus", role: .confirm) {
					editor = .create
				}
				.matchedTransitionSource(
					id: AdministrationAboutContributorEditorTarget.create.sourceID,
					in: sheetNamespace
				)
				.buttonStyle(.glassProminent)
			}
		}
		.task {
			await load()
		}
		.refreshable {
			await load()
		}
		.sheet(item: $editor) { target in
			AdministrationAboutContributorEditor(
				target: target,
				namespace: sheetNamespace,
				save: save,
				delete: delete,
				close: { editor = nil }
			)
			.navigationTransition(
				.zoom(sourceID: target.sourceID, in: sheetNamespace)
			)
			.presentationDetents([.fraction(0.6), .large])
			.appPaperPresentation()
		}
		.confirmationDialog(
			"Delete Contributor?",
			isPresented: Binding(
				get: { pendingDeletion != nil },
				set: { isPresented in
					if !isPresented {
						pendingDeletion = nil
					}
				}
			),
			titleVisibility: .visible
		) {
			if let pendingDeletion {
				Button("Delete Contributor", systemImage: "trash", role: .destructive) {
					Task {
						await delete(pendingDeletion)
					}
				}
			}
		} message: {
			Text("This removes the contributor from the About section.")
		}
	}

	private func load() async {
		do {
			contributors = try await service.administrationAboutContributors()
		} catch {
			statusBadges.present(error: error, title: "Unable to load contributors")
		}
	}

	private func save(
		_ request: AdministrationAboutContributorRequest,
		id: UUID?
	) async throws -> [AboutContributorResponse] {
		let saved = try await service.save(request, id: id)
		contributors = saved
		return saved
	}

	private func delete(_ contributor: AboutContributorResponse) async {
		do {
			contributors = try await service.deleteAboutContributor(id: contributor.id)
			pendingDeletion = nil
		} catch {
			statusBadges.present(error: error, title: "Unable to delete contributor")
		}
	}

	private func move(
		_ contributor: AboutContributorResponse,
		direction: Int
	) {
		guard let index = contributors.firstIndex(where: { $0.id == contributor.id }) else {
			return
		}

		let destination = index + direction
		guard contributors.indices.contains(destination) else {
			return
		}

		let previous = contributors
		var next = contributors
		next.swapAt(index, destination)
		contributors = next

		Task {
			do {
				contributors = try await service.reorderAboutContributors(
					next.map(\.id)
				)
			} catch {
				contributors = previous
				statusBadges.present(error: error, title: "Unable to reorder contributors")
			}
		}
	}
}

private struct AdministrationAboutContributorRow: View {
	let contributor: AboutContributorResponse
	let isFirst: Bool
	let isLast: Bool
	let isDisabled: Bool
	let namespace: Namespace.ID
	let move: (Int) -> Void
	let edit: () -> Void
	let remove: () -> Void

	var body: some View {
		HStack(spacing: 12) {
			VStack(alignment: .leading, spacing: 4) {
				Text(contributor.name)
				Text(contributor.role)
					.font(.footnote)
					.foregroundStyle(.secondary)
			}

			Spacer(minLength: 8)

			Button("Move Up", systemImage: "chevron.up") {
				move(-1)
			}
			.labelStyle(.iconOnly)
			.accessibilityLabel("Move \(contributor.name) up")
			.disabled(isFirst || isDisabled)

			Button("Move Down", systemImage: "chevron.down") {
				move(1)
			}
			.labelStyle(.iconOnly)
			.accessibilityLabel("Move \(contributor.name) down")
			.disabled(isLast || isDisabled)

			Button("Edit", systemImage: "pencil", action: edit)
				.labelStyle(.iconOnly)
				.matchedTransitionSource(
					id: "administration-about-contributor-\(contributor.id.uuidString)",
					in: namespace
				)
				.accessibilityLabel("Edit \(contributor.name)")
				.disabled(isDisabled)

			Button("Delete", systemImage: "trash", role: .destructive, action: remove)
				.labelStyle(.iconOnly)
				.accessibilityLabel("Delete \(contributor.name)")
				.disabled(isDisabled)
		}
		.accessibilityElement(children: .contain)
	}
}

private struct AdministrationAboutContributorEditor: View {
	let target: AdministrationAboutContributorEditorTarget
	let namespace: Namespace.ID
	let save: (AdministrationAboutContributorRequest, UUID?) async throws -> [AboutContributorResponse]
	let delete: (AboutContributorResponse) async throws -> Void
	let close: () -> Void

	@Environment(\.statusBadgeManager) private var statusBadges
	@State private var name: String
	@State private var role: String
	@State private var isSaving = false
	@State private var showsDeleteConfirmation = false

	init(
		target: AdministrationAboutContributorEditorTarget,
		namespace: Namespace.ID,
		save: @escaping (AdministrationAboutContributorRequest, UUID?) async throws -> [AboutContributorResponse],
		delete: @escaping (AboutContributorResponse) async throws -> Void,
		close: @escaping () -> Void
	) {
		self.target = target
		self.namespace = namespace
		self.save = save
		self.delete = delete
		self.close = close
		_name = State(initialValue: target.contributor?.name ?? "")
		_role = State(initialValue: target.contributor?.role ?? "")
	}

	var body: some View {
		NavigationStack {
			List {
				Section("Contributor") {
					TextField("Name", text: $name)
					TextField("Role", text: $role)
				}
				.glurListRowBackground()

				Section {
					Text("The contributor will appear in the About section in the current order.")
						.foregroundStyle(.secondary)
				}
				.glurListRowBackground()
			}
			.appPaperBackground()
			.appNavigationTitle(target.contributor == nil ? "Add Contributor" : "Edit Contributor", accent: true)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel, action: close)
				}

				ToolbarItem(placement: .confirmationAction) {
					Button(
						target.contributor == nil ? "Add" : "Save",
						systemImage: target.contributor == nil ? "plus" : "checkmark",
						role: .confirm
					) {
						Task {
							await saveContributor()
						}
					}
					.buttonStyle(.glassProminent)
					.disabled(!isValid || isSaving)
				}
			}
			.safeAreaBar(edge: .bottom) {
				if let contributor = target.contributor {
					Button("Delete Contributor", systemImage: "trash", role: .destructive) {
						showsDeleteConfirmation = true
					}
					.buttonStyle(.glassProminent)
					.tint(.red)
					.disabled(isSaving)
				}
			}
		}
		.navigationTransition(
			.zoom(sourceID: target.sourceID, in: namespace)
		)
		.confirmationDialog("Delete Contributor?", isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
			if let contributor = target.contributor {
				Button("Delete Contributor", systemImage: "trash", role: .destructive) {
					Task {
						await deleteContributor(contributor)
					}
				}
			}
		} message: {
			Text("This removes the contributor from the About section.")
		}
		.presentationDetents([.fraction(0.6), .large])
	}

	private var isValid: Bool {
		!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
			&& !role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	private func saveContributor() async {
		isSaving = true
		defer {
			isSaving = false
		}

		do {
			_ = try await save(
				AdministrationAboutContributorRequest(
					name: name.trimmingCharacters(in: .whitespacesAndNewlines),
					role: role.trimmingCharacters(in: .whitespacesAndNewlines)
				),
				target.contributor?.id
			)
			close()
		} catch {
			statusBadges.present(error: error, title: "Unable to save contributor")
		}
	}

	private func deleteContributor(_ contributor: AboutContributorResponse) async {
		do {
			_ = try await delete(contributor)
			close()
		} catch {
			statusBadges.present(error: error, title: "Unable to delete contributor")
		}
	}
}

private enum AdministrationAboutContributorEditorTarget: Identifiable {
	case create
	case edit(AboutContributorResponse)

	var id: String {
		sourceID
	}

	var sourceID: String {
		switch self {
			case .create:
				"administration-about-contributor-create"
			case let .edit(contributor):
				"administration-about-contributor-\(contributor.id.uuidString)"
		}
	}

	var contributor: AboutContributorResponse? {
		switch self {
			case .create:
				nil
			case let .edit(contributor):
				contributor
		}
	}
}
