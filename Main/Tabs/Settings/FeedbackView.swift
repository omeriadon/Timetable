import SwiftUI

struct FeedbackView: View {
	let close: () -> Void
	let embedsInNavigation: Bool
	let showsCloseButton: Bool
	@Environment(\.statusBadgeManager) private var badges
	@State private var category = "Feedback"
	@State private var message = ""
	@State private var isSubmitting = false

	init(
		close: @escaping () -> Void,
		embedsInNavigation: Bool = true,
		showsCloseButton: Bool = true
	) {
		self.close = close
		self.embedsInNavigation = embedsInNavigation
		self.showsCloseButton = showsCloseButton
	}

	var body: some View {
		if embedsInNavigation {
			NavigationStack {
				content
			}
		} else {
			content
		}
	}

	private var content: some View {
		List {
			Section {
				Picker("Type", selection: $category) {
					Label("Feedback", systemImage: "text.bubble")
						.foregroundStyle(.primary)
						.tag("Feedback")

					Label("Bug Report", systemImage: "ant")
						.foregroundStyle(.primary)
						.tag("Bug Report")
				}
			}
			.glurListRowBackground()

			TextField(
				text: $message,
				prompt: Text("Describe the feedback or bug"),
				axis: .vertical,
				label: {
					EmptyView()
				}
			)
			.lineLimit(5 ... 12)
			.glurListRowBackground()
		}
		.navigationBarTitleDisplayMode(.large)
		.formStyle(.grouped)
		.scrollContentBackground(.hidden)
		.scrollEdgeEffectStyle(.soft, for: .all)
		.appNavigationTitle("Report Feedback or Bug", accent: true)
		.toolbar {
			if showsCloseButton {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) { close() }
				}
			}
			ToolbarItem(placement: .confirmationAction) {
				Button("Send", systemImage: "checkmark", role: .confirm) { submit() }
					.buttonStyle(.glassProminent)
					.disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
			}
		}
	}

	private func submit() {
		isSubmitting = true
		Task {
			defer {
				isSubmitting = false
				close()
			}
			do {
				try await FeedbackService.submit(category: category, message: message)
				badges.addBadge(id: UUID(), title: "Feedback sent", priority: 3, view: .success)
			} catch {
				badges.present(error: error, title: "Unable to send feedback")
			}
		}
	}
}
