import SwiftUI

struct FriendDetailView: View {
	let friend: FriendSummary
	@State private var detail: FriendDetail?
	@State private var service = FriendService.shared
	@State private var selectedTab = FriendDetailTab.main
	@State private var action: FriendAction?
	@State private var showsReportConfirmation = false
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
		.scrollEdgeEffect()
		.appNavigationTitle(friend.friend.displayName, accent: true)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Menu("Friend actions", systemImage: "ellipsis.circle") {
					Button("Remove Friend", systemImage: "person.badge.minus", role: .destructive) {
						action = .remove
					}
					Button("Report", systemImage: "exclamationmark.bubble", role: .destructive) {
						showsReportConfirmation = true
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
		.alert("Report Friend?", isPresented: $showsReportConfirmation) {
			Button("Cancel", role: .cancel) {}
			Button("Report", role: .destructive) {
				report()
			}
		} message: {
			Text("This sends a report for review. The friend remains visible in your account.")
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
				try await service.remove(friendID: friend.friend.id)
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

	var title: String {
		"Remove Friend"
	}

	var symbol: String {
		"person.badge.minus"
	}

	var message: String {
		"This removes the friend and their timetable from your account."
	}
}
