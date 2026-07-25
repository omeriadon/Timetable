import SwiftUI

struct MessagesRootView: View {
	@Bindable var model: MessagesViewModel

	var body: some View {
		ZStack {
			let suite = UserDefaults(suiteName: "group.omeriadon.timetable") ?? .standard
			if suite.bool(forKey: "ownerIsSearchable") == true {
				VStack(spacing: 18) {
					Text("Timetable")
						.font(.largeTitle)
						.bold()
					Spacer()
						.frame(height: 50)

					Button(action: model.sendTimetable) {
						Label("Send Timetable", systemImage: "paperplane.fill")
					}
					.controlSize(.large)
					.buttonStyle(.glassProminent)
					.disabled(model.isImporting)

					Spacer()

					if let status = model.status {
						Label(status.text, systemImage: status.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
							.multilineTextAlignment(.center)
							.foregroundStyle(status.isSuccess ? .green : .secondary)
							.transition(.blurReplace)
					}
				}
				.padding(10)
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
			} else {
				ContentUnavailableView("Timetable is not shareable", systemImage: "calendar.badge.lock", description: Text("Go to settings and enable searching this timetable."))
					.foregroundStyle(.red)
			}
		}
		.monospaced()
	}
}
