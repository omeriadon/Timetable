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
			.formStyle(.grouped)
			.scrollContentBackground(.hidden)
			.safeAreaBar(edge: .top, alignment: .center, spacing: 20) {
				Text("Report Feedback or Bug")
					.padding(.horizontal, 5)
					.font(.largeTitle)
					.multilineTextAlignment(.leading)
					.lineLimit(2)
					.bold()
			}
			.scrollEdgeEffectStyle(.soft, for: .all)
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
