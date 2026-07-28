import SwiftUI

struct FriendDetailView: View {
	let friend: FriendSummary
	@State private var detail: FriendDetail?
	@State private var service = FriendService.shared
	@State private var selectedTab = FriendDetailTab.main
	@State private var action: FriendAction?
	@State private var isLoading = true
	@Environment(\.dismiss) private var dismiss
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 20) {
				FriendDetailHeader(friend: friend.friend)

				Picker("Friend detail", selection: $selectedTab) {
					ForEach(FriendDetailTab.allCases) { tab in
						Label(tab.title, systemImage: tab.symbol)
							.tag(tab)
					}
				}
				.pickerStyle(.segmented)

				if isLoading {
					ProgressView()
						.frame(maxWidth: .infinity, minHeight: 180)
				} else if let detail {
					switch selectedTab {
						case .main:
							FriendOverview(detail: detail)
						case .week:
							FriendWeek(detail: detail)
					}
				} else {
					ContentUnavailableView("Friend Unavailable", systemImage: "person.crop.circle.badge.exclamationmark")
				}
			}
			.padding()
		}
		.navigationTitle(friend.friend.displayName)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Menu("Friend actions", systemImage: "ellipsis.circle") {
					Button("Remove Friend", systemImage: "person.badge.minus", role: .destructive) {
						action = .remove
					}
					Button("Report", systemImage: "exclamationmark.bubble", role: .destructive) {
						report()
					}
					Button("Block", systemImage: "hand.raised.fill", role: .destructive) {
						action = .block
					}
				}
			}
		}
		.confirmationDialog(action?.title ?? "", isPresented: Binding(
			get: { action != nil },
			set: {
				if !$0 {
					action = nil
				}
			}
		)) {
			if let action {
				Button(action.title, systemImage: action.symbol, role: .destructive) {
					perform(action)
				}
			}
			Button("Cancel", role: .cancel) {}
		} message: {
			Text(action?.message ?? "")
		}
		.task { await load() }
	}

	private func load() async {
		defer { isLoading = false }
		do {
			detail = try await service.detail(for: friend.friend.id)
		} catch {
			badges.present(error: error, title: "Unable to load friend")
		}
	}

	private func perform(_ action: FriendAction) {
		Task {
			do {
				switch action {
					case .remove:
						try await service.remove(friendID: friend.friend.id)
					case .block:
						try await service.block(friendID: friend.friend.id)
				}
				dismiss()
			} catch {
				badges.present(error: error, title: "Unable to update friend")
			}
		}
	}

	private func report() {
		Task {
			do {
				try await TimetableDiscoveryService.shared.report(authorID: friend.friend.id)
				badges.addBadge(id: UUID(), title: "Friend reported", priority: 3, view: .success)
			} catch {
				badges.present(error: error, title: "Unable to report friend")
			}
		}
	}
}

private struct FriendDetailHeader: View {
	let friend: FriendProfile

	var body: some View {
		HStack(spacing: 16) {
			FriendAvatar(profile: friend)
			VStack(alignment: .leading, spacing: 4) {
				Text(friend.displayName)
					.font(.title2.weight(.semibold))
				if let email = friend.email {
					Text(email)
						.font(.caption.monospaced())
						.foregroundStyle(.secondary)
				}
			}
		}
		.padding(18)
		.background(Image("paper").resizable().scaledToFill())
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
	}
}

private struct FriendOverview: View {
	let detail: FriendDetail

	var body: some View {
		VStack(alignment: .leading, spacing: 18) {
			LabeledContent("Status") {
				Label("Friend", systemImage: "person.2.fill")
					.foregroundStyle(.tint)
			}
			LabeledContent("Friends since") {
				Text(detail.acceptedAt, format: .dateTime.month().day().year())
			}

			Text("Shared Classes")
				.font(.headline)
			if let timetable = detail.timetable, !timetable.subjects.isEmpty {
				ForEach(timetable.subjects.prefix(4)) { subject in
					Label(subject.id, systemImage: subject.symbol)
						.foregroundStyle(subject.colour.swiftUIColor)
				}
			} else {
				Text("No timetable has been shared yet.")
					.foregroundStyle(.secondary)
			}
		}
		.padding(18)
		.background(Image("paper").resizable().scaledToFill())
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
	}
}

private struct FriendWeek: View {
	let detail: FriendDetail

	var body: some View {
		if let timetable = detail.timetable {
			TimetablePreviewGrid(subjects: timetable.subjects)
				.padding(18)
				.background(Image("paper").resizable().scaledToFill())
				.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
		} else {
			ContentUnavailableView("No Timetable", systemImage: "calendar.badge.exclamationmark")
		}
	}
}

private enum FriendDetailTab: CaseIterable, Hashable, Identifiable {
	case main
	case week

	var id: Self {
		self
	}

	var title: String {
		self == .main ? "Main" : "Week"
	}

	var symbol: String {
		self == .main ? "person.text.rectangle" : "calendar"
	}
}

private enum FriendAction {
	case remove
	case block

	var title: String {
		self == .remove ? "Remove Friend" : "Block Friend"
	}

	var symbol: String {
		self == .remove ? "person.badge.minus" : "hand.raised.fill"
	}

	var message: String {
		switch self {
			case .remove: "This removes the friend and their timetable from your account."
			case .block: "This removes the friend and prevents future friend requests."
		}
	}
}
