//
//  first tab.swift
//  Timetable
//
//  Created by Adon Omeri on 9/8/2026.
//

import Defaults
import SwiftUI

struct FriendOverview: View {
	let detail: FriendDetail
	let friendName: String
	let locationStatus: LocationStatusItem?
	@Default(.timetable) private var ownerSubjects
	@Default(.schoolCalendar) private var schoolCalendar
	@State private var comparison = FriendTimetableComparison.empty

	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			FriendStatusCard(friend: statusSummary, style: .detail)

			sharedClassesCard(comparison.sharedClasses)

			sharedSubjectsCard(comparison.sharedSubjects)
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

	private var statusSummary: FriendSummary {
		FriendSummary(
			relationshipID: detail.relationshipID,
			friend: detail.friend,
			state: .friends,
			requestedAt: detail.acceptedAt,
			acceptedAt: detail.acceptedAt,
			timetable: detail.timetable,
			locationStatus: locationStatus
		)
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
						.foregroundStyle(.black)
						.frame(maxWidth: .infinity, alignment: .topLeading)
						.background {
							FriendWhitePaperBackground(
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
		.foregroundStyle(.white)
		.background {
			FriendGrayPaperBackground(
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
								FriendWhitePaperBackground(
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
		.foregroundStyle(.white)
		.background {
			FriendGrayPaperBackground(
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

	private func subjectLabel(_ subject: Subject) -> some View {
		Label(subject.id, systemImage: subject.symbol)
			.foregroundStyle(subject.colour.swiftUIColor)
	}
}

struct FriendInfo: View {
	let detail: FriendDetail
	let requestFriendsSinceDate: () -> Void
	let updateLocationNotificationPreferences: (Set<LocationNotificationPreference>) -> Void

	var body: some View {
		List {
			Section("Location notifications") {
				ForEach(LocationNotificationPreference.allCases, id: \.self) { preference in
					Toggle(isOn: preferenceBinding(for: preference)) {
						Label(preference.title, systemImage: preference.symbol)
					}
				}
			}

			Section("Average arrival") {
				ForEach(Array(weekdayNames.enumerated()), id: \.offset) { index, day in
					LabeledContent(day, value: averageArrival(for: index))
				}
			}

			Section {
				Button(action: requestFriendsSinceDate) {
					HStack {
						Label("Friends since", systemImage: "calendar")

						Spacer()

						Text(detail.acceptedAt, format: .dateTime.month().day().year())
							.foregroundStyle(.secondary)
					}
				}
			}
		}
		.scrollIndicators(.hidden)
		.listStyle(.insetGrouped)
	}

	private let weekdayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

	private func averageArrival(for weekdayIndex: Int) -> String {
		guard detail.weekdayAverageArrivalSecondsSinceMidnight.indices.contains(weekdayIndex),
		      let seconds = detail.weekdayAverageArrivalSecondsSinceMidnight[weekdayIndex]
		else {
			return "No Data"
		}

		return LocationArrivalTimeFormatter.string(for: seconds)
	}

	private func preferenceBinding(
		for preference: LocationNotificationPreference
	) -> Binding<Bool> {
		Binding(
			get: { detail.locationNotificationPreferences.contains(preference) },
			set: { isEnabled in
				var preferences = detail.locationNotificationPreferences
				if isEnabled {
					preferences.insert(preference)
				} else {
					preferences.remove(preference)
				}
				updateLocationNotificationPreferences(preferences)
			}
		)
	}
}

private extension LocationNotificationPreference {
	var title: String {
		switch self {
			case .withinTenMinutes:
				"Within 10 mins"
			case .withinFiveMinutes:
				"Within 5 mins"
			case .arrived:
				"Arrived"
		}
	}

	var symbol: String {
		switch self {
			case .withinTenMinutes:
				"figure.walk"
			case .withinFiveMinutes:
				"figure.run"
			case .arrived:
				"building.2"
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
			FriendBlackPaperBackground(cornerRadius: 26)
		}
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
	}
}

struct FriendshipDateChangeRequestSheet: View {
	let friendID: UUID
	let currentDate: Date
	let close: () -> Void
	@State private var requestedDate: Date
	@State private var service = FriendService.shared
	@State private var isSending = false
	@Environment(\.statusBadgeManager) private var badges

	init(friendID: UUID, currentDate: Date, close: @escaping () -> Void) {
		self.friendID = friendID
		self.currentDate = currentDate
		self.close = close
		_requestedDate = State(initialValue: currentDate)
	}

	var body: some View {
		NavigationStack {
			Form {
				DatePicker("Friends since", selection: $requestedDate, displayedComponents: .date)
			}
			.appNavigationTitle("Change Friends Since")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel, action: close)
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Request", systemImage: "paperplane.fill", role: .confirm) {
						send()
					}
					.disabled(isSending)
					.buttonStyle(.glassProminent)
				}
			}
		}
	}

	private func send() {
		isSending = true
		Task {
			defer { isSending = false }
			do {
				try await service.requestFriendsSinceDate(
					friendID: friendID,
					requestedDate: requestedDate
				)
				close()
			} catch {
				badges.present(error: error, title: "Unable to request date change")
			}
		}
	}
}

private enum FriendDetailLayout {
	static let horizontalPadding: CGFloat = 16
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

struct SharedSubject: Identifiable {
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

struct FriendSubjectContext {
	let subject: Subject
	let relationship: FriendSubjectRelationship
}

enum FriendSubjectRelationship: Hashable {
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

struct FriendSubjectContextPopover: View {
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

extension SchoolState {
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
