import Defaults
import SwiftUI

struct FriendRequestsSheet: View {
	@Environment(\.dismiss) private var dismiss
	@State private var incomingRequests: [FriendSummary] = Defaults[.incomingFriendRequests]
	@State private var outgoingRequests: [FriendSummary] = Defaults[.outgoingFriendRequests]
	@State private var service = FriendService.shared
	@State private var acceptingRequestID: UUID?
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		NavigationStack {
			List {
				if incomingRequests.isEmpty, outgoingRequests.isEmpty {
					ContentUnavailableView("No Friend Requests", systemImage: "bell.slash")
						.listRowBackground(Color.clear)
				} else {
					if !incomingRequests.isEmpty {
						Section("Incoming") {
							ForEach(incomingRequests) { request in
								incomingRequestRow(request)
							}
						}
					}

					if !outgoingRequests.isEmpty {
						Section("Sent") {
							ForEach(outgoingRequests) { request in
								outgoingRequestRow(request)
							}
						}
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

	private func incomingRequestRow(_ request: FriendSummary) -> some View {
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

	private func outgoingRequestRow(_ request: FriendSummary) -> some View {
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
			Label("Waiting", systemImage: "clock")
				.font(.caption.weight(.semibold))
				.foregroundStyle(.secondary)
		}
		.padding(.vertical, 6)
		.listRowBackground(Image("paper").resizable().scaledToFill())
	}

	private func refreshRequests() async {
		do {
			let snapshot = try await service.refreshFriendRequests()
			incomingRequests = snapshot.incoming
			outgoingRequests = snapshot.outgoing
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
				incomingRequests.removeAll { $0.id == request.id }
			} catch {
				badges.present(error: error, title: "Unable to accept friend request")
			}
		}
	}
}
