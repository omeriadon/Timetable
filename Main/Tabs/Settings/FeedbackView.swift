import SwiftUI

struct FeedbackView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.statusBadgeManager) private var badges
	@State private var category = "Feedback"
	@State private var message = ""
	@State private var isSubmitting = false

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				Text("Report Feedback or Bug")
					.font(.largeTitle)
					.lineLimit(2)
					.bold()
					.padding(.bottom, 20)

				Form {
					Section {
						Picker("Type", selection: $category) {
							Label("Feedback", systemImage: "text.bubble")
								.tag("Feedback")

							Label("Bug Report", systemImage: "ant")
								.tag("Bug Report")
						}
					}

					TextField("Describe the feedback or bug", text: $message, axis: .vertical)
						.lineLimit(5 ... 12)
				}
			}
			#if os(macOS)
			.padding(24)
			#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Send", systemImage: "checkmark", role: .confirm) { submit() }
						.disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
				}
			}
		}
	}

	private func submit() {
		isSubmitting = true
		Task {
			defer { isSubmitting = false }
			do {
				try await FeedbackService.submit(category: category, message: message)
				badges.addBadge(id: UUID(), title: "Feedback sent", priority: 3, view: .success)
				dismiss()
			} catch {
				badges.present(error: error, title: "Unable to send feedback")
			}
		}
	}
}
