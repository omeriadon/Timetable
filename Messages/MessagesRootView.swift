import SwiftUI

struct MessagesRootView: View {
	@Bindable var model: MessagesViewModel

	var body: some View {
		VStack(spacing: 18) {
			Spacer()

			Button(action: model.sendTimetable) {
				Label("Send Timetable", systemImage: "paperplane.fill")
			}
			.buttonStyle(.borderedProminent)
			.disabled(model.isImporting)

			if let status = model.status {
				Label(status.text, systemImage: status.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
					.multilineTextAlignment(.center)
					.foregroundStyle(status.isSuccess ? .green : .secondary)
					.transition(.opacity)
			}

			Spacer()
		}
		.padding(24)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(.background)
		.animation(.easeInOut(duration: 0.2), value: model.status)
		.alert(
			"Save \(model.importPrompt?.title ?? "Shared Timetable")?",
			isPresented: Binding(
				get: { model.importPrompt != nil },
				set: { isPresented in
					if !isPresented {
						model.dismissImport()
					}
				}
			)
		) {
			Button("Cancel", role: .cancel, action: model.dismissImport)
			Button("Save", action: model.importTimetable)
		} message: {
			Text("This adds the timetable to your received timetables on every signed-in device.")
		}
	}
}
