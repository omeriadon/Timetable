import SwiftUI

struct FriendSearchRow: View {
	let result: FriendSearchResult
	@State private var service = FriendService.shared
	@State private var isSending = false
	@State private var requestSent = false
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		HStack(spacing: 14) {
			FriendAvatar(profile: result.profile)

			VStack(alignment: .leading, spacing: 3) {
				Text(result.profile.displayName)
					.font(.headline)
				if let email = result.profile.email {
					Text(email)
						.font(.caption.monospaced())
						.foregroundStyle(.secondary)
				}
			}

			Spacer()
			action
		}
		.padding(.vertical, 8)
	}

	@ViewBuilder
	private var action: some View {
		switch result.relationship {
			case .friends:
				Label("Friends", systemImage: "person.2.fill")
					.font(.caption.weight(.semibold))
					.foregroundStyle(.secondary)
			case .pendingOutgoing:
				Label("Pending", systemImage: "clock")
					.font(.caption.weight(.semibold))
					.foregroundStyle(.secondary)
			case .pendingIncoming:
				Label("Requested", systemImage: "bell.badge")
					.font(.caption.weight(.semibold))
					.foregroundStyle(.tint)
			case nil:
				Button("Request", systemImage: requestSent ? "checkmark" : "person.badge.plus", role: .confirm) {
					sendRequest()
				}
				.buttonStyle(.glassProminent)
				.disabled(isSending || requestSent)
		}
	}

	private func sendRequest() {
		guard let email = result.profile.email else { return }
		isSending = true
		Task {
			defer { isSending = false }
			do {
				_ = try await service.sendRequest(to: email)
				requestSent = true
			} catch {
				badges.present(error: error, title: "Unable to send friend request")
			}
		}
	}
}
