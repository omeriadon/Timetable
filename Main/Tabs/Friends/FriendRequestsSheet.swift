import Defaults
import SwiftUI

struct FriendRequestsSheet: View {
	let close: () -> Void
	let embedsInNavigation: Bool
	let showsCloseButton: Bool
	@State private var incomingRequests: [FriendSummary] = Defaults[.incomingFriendRequests]
	@State private var outgoingRequests: [FriendSummary] = Defaults[.outgoingFriendRequests]
	@State private var service = FriendService.shared
	@State private var acceptingRequestID: UUID?
	@State private var deletingRequestID: UUID?
	@State private var requestToDelete: FriendSummary?
	@Environment(\.statusBadgeManager) private var badges

	init(
		close: @escaping () -> Void,
		embedsInNavigation: Bool = true,
		showsCloseButton: Bool = true
	) {
		self.close = close
		self.embedsInNavigation = embedsInNavigation
		self.showsCloseButton = showsCloseButton
	}

	var body: some View {
		if embedsInNavigation {
			NavigationStack {
				content
			}
		} else {
			content
		}
	}

	private var content: some View {
		List {
			if incomingRequests.isEmpty, outgoingRequests.isEmpty {
				ContentUnavailableView("No Friend Requests", systemImage: "bell.slash")
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
		.appPaperPresentation()
		.listStyle(.insetGrouped)
		.appNavigationTitle("Friend Requests")
		.toolbar {
			if showsCloseButton {
				ToolbarItem(placement: .cancellationAction) {
					Button("Close", systemImage: "xmark", role: .cancel) {
						close()
					}
					.labelStyle(.iconOnly)
					.accessibilityLabel("Close friend requests")
				}
			}
		}
		.task {
			await refreshRequests()
		}
		.refreshable {
			await refreshRequests()
		}
		.alert(
			"Delete Friend Request?",
			isPresented: Binding(
				get: { requestToDelete != nil },
				set: { isPresented in
					if !isPresented {
						requestToDelete = nil
					}
				}
			)
		) {
			if let requestToDelete {
				Button("Delete Request", systemImage: "trash", role: .destructive) {
					delete(requestToDelete)
				}
			}
			Button(role: .cancel) {}
		} message: {
			Text("This removes the pending friend request.")
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
			Button(role: .destructive) {
				requestToDelete = request
			} label: {
				Image(systemName: "trash")
			}
			.accessibilityLabel("Delete friend request")
			.disabled(deletingRequestID == request.id)
		}
		.glurListRowBackground()
		.padding(.vertical, 6)
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
			Button(role: .destructive) {
				requestToDelete = request
			} label: {
				Image(systemName: "trash")
			}
			.accessibilityLabel("Delete friend request")
			.disabled(deletingRequestID == request.id)
		}
		.glurListRowBackground()
		.padding(.vertical, 6)
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

	private func delete(_ request: FriendSummary) {
		requestToDelete = nil
		deletingRequestID = request.id
		Task {
			defer { deletingRequestID = nil }
			do {
				try await service.deleteRequest(request)
				incomingRequests.removeAll { $0.id == request.id }
				outgoingRequests.removeAll { $0.id == request.id }
			} catch {
				badges.present(error: error, title: "Unable to delete friend request")
			}
		}
	}
}
