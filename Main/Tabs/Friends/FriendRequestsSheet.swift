import Defaults
import SwiftUI

struct FriendRequestsSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Default(.incomingFriendRequests) private var requests
	@State private var service = FriendService.shared
	@State private var acceptingRequestID: UUID?
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		NavigationStack {
			List {
				if requests.isEmpty {
					ContentUnavailableView("No Friend Requests", systemImage: "bell.slash")
						.listRowBackground(Color.clear)
				} else {
					ForEach(requests) { request in
						HStack(spacing: 14) {
							FriendAvatar(profile: request.friend)
							VStack(alignment: .leading, spacing: 3) {
								Text(request.friend.displayName)
									.font(.headline)
								Text("Sent \(request.requestedAt, format: .relative(presentation: .named))")
									.font(.caption)
									.foregroundStyle(.secondary)
							}
							Spacer()
							Button("Accept", systemImage: "checkmark", role: .confirm) {
								accept(request)
							}
							.buttonStyle(.glassProminent)
							.disabled(acceptingRequestID == request.id)
						}
						.padding(.vertical, 6)
						.listRowBackground(Image("paper").resizable().scaledToFill())
					}
				}
			}
			.listStyle(.insetGrouped)
			.appNavigationTitle("Friend Requests")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					} label: {
						Image(systemName: "xmark")
					}
				}
			}
			.task {
				await refreshRequests()
			}
			.refreshable {
				await refreshRequests()
			}
		}
	}

	private func refreshRequests() async {
		do {
			try await service.refreshIncomingRequests()
		} catch {
			badges.present(error: error, title: "Unable to load friend requests")
		}
	}

	private func accept(_ request: FriendSummary) {
		acceptingRequestID = request.id
		Task {
			defer { acceptingRequestID = nil }
			do {
				try await service.accept(request)
			} catch {
				badges.present(error: error, title: "Unable to accept friend request")
			}
		}
	}
}
