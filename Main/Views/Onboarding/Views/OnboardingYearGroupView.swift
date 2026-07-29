import SwiftUI

struct OnboardingYearGroupView: View {
	@Environment(\.onboardingPageContext) private var context
	@State private var service = AdministrationService.shared
	@State private var yearGroupTags: [EventTagCatalogueTag] = []
	@State private var subscriptions: Set<UUID> = []
	@State private var selectedTagID: UUID?
	@State private var isSaving = false

	var body: some View {
		VStack(alignment: .leading, spacing: 24) {
			Text("Which year group are you in?")
				.font(.title2.bold())

			Text("This controls which year-group school events you receive. You can change it later in Settings.")
				.foregroundStyle(.secondary)

			ForEach(yearGroupTags) { tag in
				Button {
					selectedTagID = tag.id
					Task {
						await save()
					}
				} label: {
					Label(tag.displayName, systemImage: selectedTagID == tag.id ? "checkmark.circle.fill" : "circle")
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding()
						.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
				}
				.buttonStyle(.plain)
				.disabled(isSaving)
			}
		}
		.task {
			await load()
		}
		.onChange(of: selectedTagID) {
			context.configure(
				canAdvance: selectedTagID != nil && !isSaving,
				statusMessage: selectedTagID == nil ? "Select your year group to continue." : nil
			)
		}
	}

	private func load() async {
		async let catalogue = service.tagCatalogue()
		async let currentSubscriptions = service.tagSubscriptions()
		guard let loadedCatalogue = try? await catalogue, let loadedSubscriptions = try? await currentSubscriptions else {
			context.configure(canAdvance: false, statusMessage: "Unable to load year groups.")
			return
		}

		yearGroupTags = loadedCatalogue.sections.first(where: { $0.category == .yearGroup })?.tags ?? []
		subscriptions = Set(loadedSubscriptions.tagIDs)
		selectedTagID = yearGroupTags.first(where: { subscriptions.contains($0.id) })?.id
		context.configure(
			canAdvance: selectedTagID != nil,
			statusMessage: selectedTagID == nil ? "Select your year group to continue." : nil
		)
	}

	private func save() async {
		guard let selectedTagID else {
			return
		}

		isSaving = true
		context.configure(canAdvance: false, isWorking: true, statusMessage: "Saving year group…")
		defer {
			isSaving = false
		}

		let yearGroupIDs = Set(yearGroupTags.map(\.id))
		let proposed = subscriptions.subtracting(yearGroupIDs).union([selectedTagID])
		do {
			let response = try await service.replaceTagSubscriptions(proposed)
			subscriptions = Set(response.tagIDs)
			context.configure(canAdvance: true, isWorking: false, statusMessage: "Year group saved.")
		} catch {
			context.configure(canAdvance: false, isWorking: false, statusMessage: "Unable to save year group.")
		}
	}
}
