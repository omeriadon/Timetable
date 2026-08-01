import SwiftUI

struct FriendSearchRow: View {
	let result: FriendSearchResult
	@State private var service = FriendService.shared
	@State private var isSending = false
	@State private var requestSent = false
	@State private var relationship: FriendRelationshipState?
	@Environment(\.statusBadgeManager) private var badges

	init(result: FriendSearchResult) {
		self.result = result
		_relationship = State(initialValue: result.relationship)
	}

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

			Spacer(minLength: 1)
			action
		}
		.padding(.vertical, 8)
		.onChange(of: result.relationship) { _, value in
			relationship = value
			requestSent = value == .pendingOutgoing
		}
	}

	@ViewBuilder
	private var action: some View {
		switch relationship {
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
				.tint(.blue)
				.foregroundStyle(.white)
				.disabled(isSending || requestSent)
		}
	}

	private func sendRequest() {
		guard let email = result.profile.email else {
			PrintError("Friend search result has no email address", category: .network)
			return
		}
		isSending = true
		Print("Sending friend request", category: .network)
		Task {
			defer { isSending = false }
			do {
				let summary = try await service.sendRequest(to: email)
				relationship = summary.state
				requestSent = summary.state == .pendingOutgoing
				Print("Friend request sent", category: .network)
			} catch let NetworkError.server(statusCode, response)
				where statusCode == 409 && response.message == "You are already friends."
			{
				relationship = .friends
				try? await service.refresh()
				Print("Friend relationship refreshed after conflict", category: .network)
			} catch {
				badges.present(error: error, title: "Unable to send friend request")
				PrintError("Friend request failed", category: .network, error: error)
			}
		}
	}
}
