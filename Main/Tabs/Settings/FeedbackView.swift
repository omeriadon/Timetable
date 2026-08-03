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
		Form {
			Section {
				Picker("Type", selection: $category) {
					Label("Feedback", systemImage: "text.bubble")
						.foregroundStyle(.white)
						.tag("Feedback")

					Label("Bug Report", systemImage: "ant")
						.foregroundStyle(.white)
						.tag("Bug Report")
				}
				#if os(macOS)
				.pickerStyle(.radioGroup)
				#endif
			}

			TextField(
				text: $message,
				prompt: Text("Describe the feedback or bug"),
				axis: .vertical,
				label: {
					EmptyView()
				}
			)
			.lineLimit(5 ... 12)
			#if os(macOS)
				.labelsHidden()
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.horizontal, 4)
				.padding(.bottom, 3)
				.background {
					RoundedRectangle(cornerRadius: 3)
						.fill(Color(red: 0.13, green: 0.14, blue: 0.15))
				}
			#endif // os(macOS)
		}
		#if os(iOS)
		.navigationBarTitleDisplayMode(.large)
		#endif
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
