import SwiftUI

struct FriendSearchRow: View {
	let result: FriendSearchResult
	@State private var service = FriendService.shared
	@State private var isSending = false
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
			}

			Spacer(minLength: 1)
			action
		}
		.padding(.vertical, 8)
		.accessibilityElement(children: .combine)
		.accessibilityLabel(accessibilityLabel)
		.onChange(of: result.relationship) { _, value in
			relationship = value
		}
	}

	private var accessibilityLabel: String {
		switch relationship {
			case .friends:
				"\(result.profile.displayName), friends"
			case .pendingOutgoing:
				"\(result.profile.displayName), friend request sent"
			case .pendingIncoming:
				"\(result.profile.displayName), incoming friend request"
			case nil:
				result.profile.displayName
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
				Label("Request Sent", systemImage: "clock")
					.font(.caption.weight(.semibold))
					.foregroundStyle(.secondary)
			case .pendingIncoming:
				Label("Incoming Request", systemImage: "bell.badge")
					.font(.caption.weight(.semibold))
					.foregroundStyle(.tint)
			case nil:
				Button("Request", systemImage: "person.badge.plus") {
					sendRequest()
				}
				.buttonStyle(.glassProminent)
				.tint(.blue)
				.foregroundStyle(.primary)
				.disabled(isSending)
		}
	}

	private func sendRequest() {
		isSending = true
		Print("Sending friend request", category: .network)
		Task {
			defer { isSending = false }
			do {
				let summary = try await service.sendRequest(to: result.profile.id)
				relationship = summary.state
				Print("Friend request sent", category: .network)
			} catch {
				badges.present(error: error, title: "Unable to send friend request")
				PrintError("Friend request failed", category: .network, error: error)
			}
		}
	}
}
