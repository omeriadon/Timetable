import SwiftUI

struct AdministrationBroadcastNotificationView: View {
	@State private var service = AdministrationService.shared
	@State private var title = ""
	@State private var subtitle = ""
	@State private var notifBody = ""

	var body: some View {
		Form {
			TextField("Title", text: $title)
			TextField("Subtitle", text: $subtitle)
			TextField("Message", text: $notifBody, axis: .vertical)
				.lineLimit(4 ... 8)
		}
		.appNavigationTitle("Broadcast Notification")
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button("Send", systemImage: "paperplane.fill", role: .confirm) {
					send()
				}
				.disabled(
					title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
						|| subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
						|| notifBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
				)
				.buttonStyle(.glassProminent)
			}
		}
	}

	private func send() {
		let request = BroadcastNotificationRequest(
			title: title,
			subtitle: subtitle,
			body: notifBody
		)

		Task {
			try? await service.broadcastNotification(request)
		}
	}
}
