import Defaults
import SwiftUI

struct OnboardingYearGroupView: View {
	let context: OnboardingPageContext
	@State private var service = AdministrationService.shared
	@State private var yearGroupTags: [EventTagCatalogueTag] = []
	@State private var subscriptions: Set<UUID> = []
	@State private var selectedTagID: UUID?
	@State private var isSaving = false
	@State private var isLoading = false
	@State private var loadFailed = false

	var body: some View {
		VStack(alignment: .leading, spacing: 24) {
			Text("Which year group are you in?")
				.font(.title2.bold())

			Text("This controls which year-group school events you receive. You can change it later in Settings.")
				.foregroundStyle(.secondary)

			if isLoading, yearGroupTags.isEmpty {
				ProgressView("Loading year groups…")
					.frame(maxWidth: .infinity)
			} else if yearGroupTags.isEmpty {
				ContentUnavailableView(
					loadFailed ? "Unable to Load Year Groups" : "No Year Groups Available",
					systemImage: loadFailed ? "arrow.trianglehead.2.clockwise" : "person.3",
					description: Text(
						loadFailed
							? "The year groups could not be loaded from the server."
							: "No year groups are currently configured."
					)
				)

				if loadFailed {
					Button("Retry", systemImage: "arrow.clockwise") {
						Task {
							await load()
						}
					}
					.buttonStyle(.glassProminent)
				}
			} else {
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
		let cachedCatalogue = Defaults[.eventTagCatalogue]
		let cachedSubscriptions = Set(Defaults[.eventTagSubscriptionIDs])
		yearGroupTags = cachedCatalogue.sections.first(where: { $0.category == .yearGroup })?.tags ?? []
		subscriptions = cachedSubscriptions
		selectedTagID = yearGroupTags.first(where: { subscriptions.contains($0.id) })?.id
		if !yearGroupTags.isEmpty {
			context.configure(canAdvance: selectedTagID != nil, isWorking: false, statusMessage: nil)
		}
		isLoading = true
		loadFailed = false
		if yearGroupTags.isEmpty {
			context.configure(canAdvance: false, isWorking: true, statusMessage: "Loading year groups…")
		}
		defer {
			isLoading = false
		}

		async let catalogue = service.tagCatalogue()
		async let currentSubscriptions = service.tagSubscriptions()
		guard let loadedCatalogue = try? await catalogue else {
			loadFailed = true
			context.configure(canAdvance: false, isWorking: false, statusMessage: "Unable to load year groups.")
			return
		}

		yearGroupTags = loadedCatalogue.sections.first(where: { $0.category == .yearGroup })?.tags ?? []
		if let loadedSubscriptions = try? await currentSubscriptions {
			subscriptions = Set(loadedSubscriptions.tagIDs)
		} else {
			subscriptions = []
		}

		selectedTagID = yearGroupTags.first(where: { subscriptions.contains($0.id) })?.id
		guard !yearGroupTags.isEmpty else {
			context.configure(canAdvance: false, isWorking: false, statusMessage: "No year groups are available.")
			return
		}

		context.configure(
			canAdvance: selectedTagID != nil,
			isWorking: false,
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
