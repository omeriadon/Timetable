import SwiftUI
import Defaults

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
	@Default(.timetable) private var ownerSubjects

	var body: some View {
		let comparison = FriendTimetableComparison(
			ownerSubjects: ownerSubjects,
			friendSubjects: detail.timetable?.subjects ?? []
		)

		VStack(alignment: .leading, spacing: 18) {
			LabeledContent("Friends since") {
				Text(detail.acceptedAt, format: .dateTime.month().day().year())
			}

			Text("Shared Classes")
				.font(.headline)
			if comparison.sharedClasses.isEmpty {
				Text("No shared classes.")
					.foregroundStyle(.secondary)
			} else {
				ForEach(comparison.sharedClasses) { sharedClass in
					VStack(alignment: .leading, spacing: 3) {
						Label(sharedClass.subjectName, systemImage: sharedClass.symbol)
							.foregroundStyle(sharedClass.colour.swiftUIColor)
						if !sharedClass.classroom.isEmpty {
							Text(sharedClass.classroom)
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
						Text(sharedClass.slotSummary)
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				}
			}

			Text("Shared Subjects")
				.font(.headline)
			if comparison.sharedSubjects.isEmpty {
				Text("No shared subjects.")
					.foregroundStyle(.secondary)
			} else {
				ForEach(comparison.sharedSubjects) { subject in
					Label(subject.subjectName, systemImage: subject.symbol)
						.foregroundStyle(subject.colour.swiftUIColor)
				}
			}
		}
		.padding(18)
		.background(Image("paper").resizable().scaledToFill())
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
	}
}

private struct FriendTimetableComparison {
	let sharedClasses: [SharedClass]
	let sharedSubjects: [SharedSubject]

	init(ownerSubjects: [Subject], friendSubjects: [Subject]) {
		var classes: [SharedClass] = []
		var subjects: [SharedSubject] = []
		var seenClassKeys = Set<String>()
		var seenSubjectKeys = Set<String>()

		for ownerSubject in ownerSubjects {
			let normalizedSubject = Self.normalized(ownerSubject.id)
			let matchingSubjects = friendSubjects.filter {
				Self.normalized($0.id) == normalizedSubject
			}

			for friendSubject in matchingSubjects {
				let subjectKey = normalizedSubject
				if seenSubjectKeys.insert(subjectKey).inserted {
					subjects.append(
						SharedSubject(
							subjectName: ownerSubject.id,
							symbol: ownerSubject.symbol,
							colour: ownerSubject.colour
						)
					)
				}

				let ownerClassroom = Self.normalized(ownerSubject.classroom.editorValue)
				let friendClassroom = Self.normalized(friendSubject.classroom.editorValue)
				guard ownerClassroom == friendClassroom else {
					continue
				}

				let overlappingSlots = ownerSubject.slots.filter(friendSubject.slots.contains)
				guard !overlappingSlots.isEmpty else {
					continue
				}

				let classKey = "\(normalizedSubject)|\(ownerClassroom)"
				guard seenClassKeys.insert(classKey).inserted else {
					continue
				}

				classes.append(
					SharedClass(
						subjectName: ownerSubject.id,
						symbol: ownerSubject.symbol,
						colour: ownerSubject.colour,
						classroom: ownerSubject.classroom.displayName,
						slots: overlappingSlots
					)
				)
			}
		}

		sharedClasses = classes
		sharedSubjects = subjects
	}

	private static func normalized(_ value: String) -> String {
		value
			.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
			.split(whereSeparator: \.isWhitespace)
			.joined(separator: " ")
	}
}

private struct SharedClass: Identifiable {
	let subjectName: String
	let symbol: String
	let colour: RGBAColor
	let classroom: String
	let slots: [Slot]

	var id: String {
		"\(subjectName)|\(classroom)"
	}

	var slotSummary: String {
		slots
			.sorted { ($0.day, $0.session) < ($1.day, $1.session) }
			.map { "\(TimetableLayout.shortDayLabels[$0.day]) \(TimetableLayout.sessions[$0.session])" }
			.joined(separator: ", ")
	}
}

private struct SharedSubject: Identifiable {
	let subjectName: String
	let symbol: String
	let colour: RGBAColor

	var id: String {
		subjectName
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
