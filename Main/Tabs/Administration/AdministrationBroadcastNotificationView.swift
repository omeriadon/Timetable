import SwiftUI

struct AdministrationBroadcastNotificationView: View {
	@State private var service = AdministrationService.shared
	@State private var title = ""
	@State private var subtitle = ""
	@State private var notifBody = ""
	@State private var onlySendToOptedInUsers = true
	@State private var isSending = false
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List {
			TextField("Title *", text: $title)
				.glurListRowBackground()
			TextField("Subtitle", text: $subtitle)
				.glurListRowBackground()
			TextField("Message", text: $notifBody, axis: .vertical)
				.lineLimit(4 ... 8)
				.glurListRowBackground()
			Toggle(isOn: $onlySendToOptedInUsers) {
				Text("Only Send to Opted-In Users")
				Text("When disabled, this broadcast is sent to every registered device regardless of the user's Special Event Notifications setting.")
			}
			.glurListRowBackground()
		}
		.appPaperBackground()
		.appNavigationTitle("Broadcast Notification", accent: true)
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button("Send", systemImage: "paperplane.fill", role: .confirm) {
					send()
				}
				.disabled(
					title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending
				)
				.buttonStyle(.glassProminent)
			}
		}
	}

	private func send() {
		guard !isSending else {
			return
		}
		isSending = true
		let badgeID = UUID()
		badges.addBadge(
			id: badgeID,
			title: "Sending broadcast",
			priority: 3,
			view: .progressView
		)

		let request = BroadcastNotificationRequest(
			title: title,
			subtitle: subtitle.nilIfEmpty,
			body: notifBody.nilIfEmpty,
			respectsUserPreference: onlySendToOptedInUsers
		)

		Task {
			defer {
				isSending = false
			}

			do {
				_ = try await service.broadcastNotification(request)
				title = ""
				subtitle = ""
				notifBody = ""
				badges.updateBadge(
					id: badgeID,
					title: "Broadcast sent",
					view: .success
				)
			} catch {
				badges.updateBadge(
					id: badgeID,
					title: "Unable to send broadcast",
					secondaryText: error.localizedDescription,
					view: .error
				)
			}
		}
	}
}

private extension String {
	var nilIfEmpty: String? {
		let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmed.isEmpty ? nil : trimmed
	}
}
