import Defaults
import SwiftUI

struct FriendDetailView: View {
	let friend: FriendSummary
	let close: () -> Void
	@State private var detail: FriendDetail?
	@State private var service = FriendService.shared
	@State private var selectedTab = FriendDetailTab.main
	@State private var scrollPosition: Int?
	@State private var action: FriendAction?
	@State private var showsReportConfirmation = false
	@State private var isLoading = true
	@Environment(\.statusBadgeManager) private var badges
	@Environment(\.appPresentation) private var presentation

	private var displayedFriendName: String {
		detail?.friend.displayName ?? friend.friend.displayName
	}

	private var displayedFriendProfile: FriendProfile {
		detail?.friend ?? friend.friend
	}

	var body: some View {
		NavigationStack {
			Group {
				if isLoading {
					ProgressView()
						.frame(maxWidth: .infinity, minHeight: 180)
				} else if let detail {
					ScrollView(.horizontal) {
						HStack(spacing: 0) {
							ScrollView {
								FriendOverview(detail: detail, friendName: detail.friend.displayName)
							}
							.containerRelativeFrame(.horizontal)
							.id(0)

							ScrollView {
								FriendWeek(detail: detail)
									.padding(.top, 14)
							}
							.containerRelativeFrame(.horizontal)
							.id(1)
						}
						.scrollTargetLayout()
					}
					.scrollTargetBehavior(.paging)
					.scrollIndicators(.hidden)
					.scrollPosition(id: $scrollPosition)
				} else {
					ContentUnavailableView("Friend Unavailable", systemImage: "person.crop.circle.badge.exclamationmark")
				}
			}
			.foregroundStyle(.black)
			.scrollEdgeEffectStyle(.soft, for: .top)
			.safeAreaBar(edge: .top, alignment: .center, spacing: 0) {
				TabsPicker(
					items: FriendDetailTab.allCases.map { ($0.title, $0.symbol) },
					selection: Binding(
						get: { FriendDetailTab.allCases.firstIndex(of: selectedTab) ?? 0 },
						set: { index in
							guard FriendDetailTab.allCases.indices.contains(index) else {
								return
							}

							selectedTab = FriendDetailTab.allCases[index]
						}
					)
				)
				.frame(height: 40)
				.padding(.horizontal)
			}
			.onChange(of: selectedTab) { _, selectedTab in
				withAnimation {
					scrollPosition = FriendDetailTab.allCases.firstIndex(of: selectedTab)
				}
			}
			.onChange(of: scrollPosition) { _, scrollPosition in
				guard let scrollPosition,
				      FriendDetailTab.allCases.indices.contains(scrollPosition)
				else {
					return
				}
				selectedTab = FriendDetailTab.allCases[scrollPosition]
			}
			.toolbar {
				if presentation == .iOS {
					ToolbarItem(placement: .cancellationAction) {
						Button("Close", systemImage: "xmark", role: .cancel) {
							close()
						}
						.labelStyle(.iconOnly)
					}
				}

				ToolbarItem(placement: .principal) {
					HStack {
						FriendAvatar(profile: displayedFriendProfile, size: 44)
						Text(displayedFriendName)
							.font(.largeTitle)
							.bold()
							.monospaced()
					}
				}
				.sharedBackgroundVisibility(.hidden)
				.contentMarginsRemoved()

				ToolbarItem(placement: .primaryAction) {
					Menu("Friend actions", systemImage: "ellipsis") {
						Button("Remove Friend", systemImage: "person.badge.minus", role: .destructive) {
							action = .remove
						}
						Button("Report", systemImage: "exclamationmark.bubble", role: .destructive) {
							showsReportConfirmation = true
						}
					}
					.labelStyle(.iconOnly)
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
	}

	private func load() async {
		defer { isLoading = false }
		do {
			detail = try await service.detail(for: friend.friend.id)
		} catch {
			badges.present(error: error, title: "Unable to load friend")
		}
	}

	private func perform(_: FriendAction) {
		Task {
			do {
				try await service.remove(friendID: friend.friend.id)
				close()
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
		.background {
			FriendPaperBackground(cornerRadius: 26)
		}
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
	}
}

private struct FriendOverview: View {
	let detail: FriendDetail
	let friendName: String
	@Default(.timetable) private var ownerSubjects
	@Default(.schoolCalendar) private var schoolCalendar
	@State private var comparison = FriendTimetableComparison.empty

	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			currentAndNextClasses

			sharedClassesCard(comparison.sharedClasses)

			sharedSubjectsCard(comparison.sharedSubjects)

			VStack(alignment: .leading, spacing: 6) {
				Text("Friends since")
					.font(.headline)
				Text(detail.acceptedAt, format: .dateTime.month().day().year())
					.foregroundStyle(.secondary)
			}
			.padding(14)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background {
				FriendPaperBackground(
					cornerRadius: FriendDetailLayout.cardCornerRadius
				)
			}
			.glassEffect(
				.clear.interactive(),
				in: RoundedRectangle(
					cornerRadius: FriendDetailLayout.cardCornerRadius,
					style: .continuous
				)
			)
		}
		.padding(.vertical, 14)
		.padding(.horizontal, FriendDetailLayout.horizontalPadding)
		.frame(maxWidth: .infinity, alignment: .leading)
		.task(id: FriendTimetableComparisonInput(
			ownerSubjects: ownerSubjects,
			friendSubjects: detail.timetable?.subjects ?? []
		)) {
			comparison = FriendTimetableComparison(
				ownerSubjects: ownerSubjects,
				friendSubjects: detail.timetable?.subjects ?? []
			)
		}
	}

	private func sharedClassesCard(_ classes: [SharedClass]) -> some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Shared Classes")
				.font(.title3)

			if classes.isEmpty {
				Text("No shared classes.")
					.foregroundStyle(.secondary)
			} else {
				ForEach(Array(classes.enumerated()), id: \.offset) { _, sharedClass in
					FriendSubjectButton(context: sharedClass.context, friendName: friendName) {
						HStack(alignment: .top, spacing: 12) {
							Label(sharedClass.subjectName, systemImage: sharedClass.symbol)
								.foregroundStyle(sharedClass.colour.swiftUIColor)

							Spacer()

							VStack(alignment: .trailing, spacing: 3) {
								Text(sharedClass.classroom)
								Text(sharedClass.slotSummary)
									.font(.footnote)
									.foregroundStyle(.secondary)
							}
						}
						.padding(14)
						.frame(maxWidth: .infinity, alignment: .topLeading)
						.background {
							FriendPaperBackground(
								cornerRadius: FriendDetailLayout.itemCornerRadius
							)
						}
						.clipShape(
							RoundedRectangle(
								cornerRadius: FriendDetailLayout.itemCornerRadius,
								style: .continuous
							)
						)
						.glassEffect(
							.clear.interactive(),
							in: RoundedRectangle(
								cornerRadius: FriendDetailLayout.itemCornerRadius,
								style: .continuous
							)
						)
					}
				}
			}
		}
		.padding(14)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background {
			FriendBrownPaperBackground(
				cornerRadius: FriendDetailLayout.cardCornerRadius
			)
		}
		.glassEffect(
			.clear.interactive(),
			in: RoundedRectangle(
				cornerRadius: FriendDetailLayout.cardCornerRadius,
				style: .continuous
			)
		)
	}

	func sharedSubjectsCard(_ subjects: [SharedSubject]) -> some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Shared Subjects")
				.font(.title3)

			if subjects.isEmpty {
				Text("No shared subjects.")
					.foregroundStyle(.secondary)
			} else {
				ForEach(subjects) { subject in
					FriendSubjectButton(context: subject.context, friendName: friendName) {
						Label(subject.subjectName, systemImage: subject.symbol)
							.foregroundStyle(subject.colour.swiftUIColor)
							.padding(14)
							.frame(maxWidth: .infinity, alignment: .leading)
							.background {
								FriendPaperBackground(
									cornerRadius: FriendDetailLayout.itemCornerRadius
								)
							}
							.clipShape(
								RoundedRectangle(
									cornerRadius: FriendDetailLayout.itemCornerRadius,
									style: .continuous
								)
							)
							.glassEffect(
								.clear.interactive(),
								in: RoundedRectangle(
									cornerRadius: FriendDetailLayout.itemCornerRadius,
									style: .continuous
								)
							)
					}
				}
			}
		}
		.padding(14)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background {
			FriendBrownPaperBackground(
				cornerRadius: FriendDetailLayout.cardCornerRadius
			)
		}
		.glassEffect(
			.clear.interactive(),
			in: RoundedRectangle(
				cornerRadius: FriendDetailLayout.cardCornerRadius,
				style: .continuous
			)
		)
	}

	@ViewBuilder
	private var currentAndNextClasses: some View {
		let subjects = detail.timetable?.subjects ?? []
		let state = SchoolStateEngine.calculate(
			at: TimetableClock.now,
			subjects: subjects,
			calendar: SchoolCalendarProjection.perthCalendar,
			schoolCalendar: schoolCalendar
		)

		if let currentSubject = state.currentSubject {
			currentAndNextClassesCard(isCompact: state.nextSubject == nil) {
				VStack(alignment: .leading, spacing: 8) {
					contextButton(title: "Current Class", subject: currentSubject)

					if let nextSubject = state.nextSubject {
						contextButton(title: "Up Next", subject: nextSubject)
					}
				}
			}
		} else if let nextSubject = state.nextSubject {
			currentAndNextClassesCard(isCompact: true) {
				contextButton(title: "Next Class", subject: nextSubject)
			}
		}
	}

	private func currentAndNextClassesCard(
		isCompact: Bool,
		@ViewBuilder content: () -> some View
	) -> some View {
		let shape = isCompact
			? AnyShape(Capsule())
			: AnyShape(
				RoundedRectangle(
					cornerRadius: FriendDetailLayout.cardCornerRadius,
					style: .continuous
				)
			)

		return content()
			.padding(14)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background {
				FriendBrownPaperBackground(shape: shape)
			}
			.glassEffect(
				.clear.interactive(),
				in: shape
			)
	}

	private func contextButton(
		title: String,
		subject: Subject
	) -> some View {
		LabeledContent(title) {
			Label(subject.id, systemImage: subject.symbol)
				.foregroundStyle(subject.colour.swiftUIColor)
		}
	}
}

private struct FriendBrownPaperBackground: View {
	let shape: AnyShape

	init(cornerRadius: CGFloat) {
		shape = AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
	}

	init(shape: AnyShape) {
		self.shape = shape
	}

	var body: some View {
		GeometryReader { proxy in
			Image("paper")
				.resizable()
				.scaledToFill()
				.frame(width: proxy.size.width, height: proxy.size.height)
				.clipped()
		}
		.clipShape(shape)
	}
}

private enum FriendDetailLayout {
	static let horizontalPadding: CGFloat = 8
	static let cardCornerRadius: CGFloat = 25
	static let itemCornerRadius: CGFloat = 13
}

private struct FriendSubjectButton<Label: View>: View {
	let context: FriendSubjectContext
	let friendName: String
	@ViewBuilder let label: () -> Label
	@State private var showsPopover = false

	var body: some View {
		Button {
			showsPopover = true
		} label: {
			label()
		}
		.buttonStyle(.plain)
		.contentShape(Rectangle())
		.popover(
			isPresented: $showsPopover,
			attachmentAnchor: .rect(.bounds)
		) {
			FriendSubjectContextPopover(context: context, friendName: friendName)
				.padding(10)
		}
	}
}

private struct FriendTimetableComparison {
	let sharedClasses: [SharedClass]
	let sharedSubjects: [SharedSubject]

	static let empty = FriendTimetableComparison(
		ownerSubjects: [],
		friendSubjects: []
	)

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
							colour: ownerSubject.colour,
							subject: ownerSubject
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
						subject: ownerSubject,
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

private struct FriendTimetableComparisonInput: Hashable {
	let ownerSubjects: [Subject]
	let friendSubjects: [Subject]
}

private struct SharedClass: Identifiable {
	let subjectName: String
	let symbol: String
	let colour: RGBAColor
	let subject: Subject
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

	var context: FriendSubjectContext {
		FriendSubjectContext(
			subject: subject,
			relationship: .sharedClass(slotSummary: slotSummary)
		)
	}
}

private struct SharedSubject: Identifiable {
	let subjectName: String
	let symbol: String
	let colour: RGBAColor
	let subject: Subject

	var id: String {
		subjectName
	}

	var context: FriendSubjectContext {
		FriendSubjectContext(subject: subject, relationship: .sharedSubject)
	}
}

private struct FriendSubjectContext {
	let subject: Subject
	let relationship: FriendSubjectRelationship
}

private enum FriendSubjectRelationship: Hashable {
	case current
	case next
	case sharedClass(slotSummary: String)
	case sharedSubject

	var title: String {
		switch self {
			case .current:
				"Current Class"
			case .next:
				"Next Class"
			case .sharedClass:
				"Shared Class"
			case .sharedSubject:
				"Shared Subject"
		}
	}
}

private struct FriendSubjectContextPopover: View {
	let context: FriendSubjectContext
	let friendName: String

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Label(context.subject.id, systemImage: context.subject.symbol)
				.font(.title3.weight(.semibold))

			contextRow("Classroom", value: context.subject.classroom.displayName, systemImage: "door.left.hand.open")
			contextRow("Teacher", value: context.subject.teacher.displayName, systemImage: "person.crop.circle")

			if case let .sharedClass(slotSummary) = context.relationship {
				matchingPeriodsRow(slotSummary)
			}
		}
		.frame(width: 290, alignment: .leading)
		.padding()
		.foregroundStyle(.white)
		.presentationCompactAdaptation(.popover)
	}

	private func matchingPeriodsRow(_ value: String) -> some View {
		VStack(alignment: .leading, spacing: 4) {
			Text("Matching periods")
				.font(.caption)
			Text(value)
				.multilineTextAlignment(.trailing)
				.frame(maxWidth: .infinity, alignment: .trailing)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	@ViewBuilder
	private func contextRow(_ title: String, value: String, systemImage: String) -> some View {
		if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			LabeledContent(title) {
				Label(value, systemImage: systemImage)
					.labelStyle(.titleAndIcon)
					.multilineTextAlignment(.trailing)
			}
		}
	}
}

private extension SchoolState {
	var currentSubject: Subject? {
		if case let .lesson(lesson) = self {
			return lesson.subject
		}
		return nil
	}

	var nextSubject: Subject? {
		if case let .subject(subject)? = nextDestination {
			return subject
		}

		return nil
	}
}

private struct FriendWeek: View {
	let detail: FriendDetail

	var body: some View {
		if let timetable = detail.timetable {
			TimetablePreviewGrid(subjects: timetable.subjects)
				.padding(18)
				.background {
					FriendPaperBackground(cornerRadius: 26)
				}
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
