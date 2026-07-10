import SwiftUI

struct FeedbackView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.statusBadgeManager) private var badges
	@State private var category = "Feedback"
	@State private var message = ""
	@State private var isSubmitting = false

	var body: some View {
		NavigationStack {
			Form {
				Picker("Type", selection: $category) {
					Text("Feedback").tag("Feedback")
					Text("Bug Report").tag("Bug Report")
				}
				TextField("Describe the feedback or bug", text: $message, axis: .vertical)
					.lineLimit(5 ... 12)
			}
			.appNavigationTitle("Report Feedback or Bug", style: .subview)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel", role: .cancel) { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Send") { submit() }
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
