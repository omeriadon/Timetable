import SwiftUI

struct AdministrationBroadcastNotificationView: View {
	@State private var service = AdministrationService.shared
	@State private var title = ""
	@State private var subtitle = ""
	@State private var notifBody = ""
	@State private var isSending = false
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		Form {
			TextField("Title *", text: $title)
			TextField("Subtitle", text: $subtitle)
			TextField("Message", text: $notifBody, axis: .vertical)
				.lineLimit(4 ... 8)
		}
		.appGroupedFormStyle()
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
			body: notifBody.nilIfEmpty
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
