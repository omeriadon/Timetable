//
//   CalendarImportView.swift
//   Main
//
//   Created by Adon Omeri on 27/4/2026.
//

import Defaults
import EventKit
import SwiftUI

struct CalendarImportView: View {
	let close: () -> Void = {}
	var dismissesWhenFinished = true
	var completion: ((Bool) -> Void)?

	@Default(.timetable) var subjects

	@State private var calendarImportStatus = CalendarImportStatus.loading
	@State private var calendarImportStep = CalendarImportStep.checkingAuthorisation
	@State private var errorResetTask: Task<Void, Never>?
	@State private var subjectTagProposal: SubjectTagReplacementProposal?
	@State private var isApplyingSubjectTags = false
	@State private var successDetail = "You can change subjects, teachers and classrooms in settings if they have issues."
	@State private var administrationService = AdministrationService.shared

	var body: some View {
		VStack(spacing: 14) {
			ZStack {
				switch calendarImportStatus {
					case .loading:
						Image(systemName: "calendar.badge.clock")
							.symbolEffect(.breathe)
							.transition(.blurReplace)
					case .success:
						Image(systemName: "checkmark.circle")
							.foregroundStyle(.green)
							.transition(.blurReplace)
					case .error:
						Image(systemName: "exclamationmark.triangle.fill")
							.transition(.blurReplace)
				}
			}
			.font(.largeTitle.scaled(by: 1.5))

			ZStack {
				switch calendarImportStatus {
					case .loading:
						Text("Importing timetable...")
							.transition(.blurReplace)
					case .success:
						VStack {
							Text("Import complete")
							Text(successDetail)
								.font(.body)
						}
						.padding(.bottom, 20)
						.transition(.blurReplace)
					case .error:
						Text("Import failed")
							.transition(.blurReplace)
				}
			}
			.font(.title2.scaled(by: 1.2))

			Text(calendarImportStep.text)
				.contentTransition(.numericText())

			HStack(alignment: .center) {
				Text("\(calendarImportStep.progress)")
					.contentTransition(.numericText())

				Gauge(
					value: Double(calendarImportStep.progress),
					in: 0 ... Double(calendarImportStep.total)
				) {
					Text("")
				} currentValueLabel: {
					Text("")
				} minimumValueLabel: {
					Text("")
				} maximumValueLabel: {
					Text("")
				}

				Text("\(calendarImportStep.total)")
			}

			if case .error = calendarImportStatus {
				if !dismissesWhenFinished {
					Button("Try Again", systemImage: "arrow.clockwise") {
						beginImportAttempt()
						Task { await performCalendarImport() }
					}
					.buttonStyle(.glassProminent)
				}
			}
		}
		.animation(.easeInOut, value: calendarImportStep)
		.task {
			beginImportAttempt()
			await performCalendarImport()
		}
		.onDisappear {
			errorResetTask?.cancel()
		}
		.confirmationDialog(
			"Replace Subject Tags?",
			isPresented: Binding(
				get: { subjectTagProposal != nil },
				set: { _ in }
			),
			titleVisibility: .visible
		) {
			Button("Keep Current Subject Tags", systemImage: "tag.slash") {
				keepCurrentSubjectTags()
			}
			.disabled(isApplyingSubjectTags)

			Button("Replace Subject Tags", systemImage: "arrow.triangle.2.circlepath", role: .confirm) {
				replaceSubjectTags()
			}
			.buttonStyle(.glassProminent)
			.disabled(isApplyingSubjectTags)
		} message: {
			Text(subjectTagProposal?.message ?? "")
		}
		.ignoresSafeArea()
		.padding([.horizontal], 32)
		.presentationDetents(dismissesWhenFinished ? [.fraction(0.55)] : [.large])
		.interactiveDismissDisabled()
		.presentationDragIndicator(.hidden)
	}

	func moveForward(to step: CalendarImportStep) {
		calendarImportStep = step
	}

	func errorAndExit(_ error: String) {
		calendarImportStep = .error(error)
		calendarImportStatus = .error
		completion?(false)
		scheduleErrorReset(for: error)
		Task {
			PrintError("[iOS] error: \(error)")
			if dismissesWhenFinished {
				try? await Task.sleep(for: .seconds(2))
				close()
			}
		}
	}

	func beginImportAttempt() {
		errorResetTask?.cancel()
		errorResetTask = nil
		subjectTagProposal = nil
		isApplyingSubjectTags = false
		successDetail = "You can change subjects, teachers and classrooms in settings if they have issues."
		calendarImportStatus = .loading
		calendarImportStep = .checkingAuthorisation
	}

	func scheduleErrorReset(for error: String) {
		errorResetTask?.cancel()
		errorResetTask = Task {
			try? await Task.sleep(for: .seconds(4))
			guard !Task.isCancelled else {
				return
			}
			guard case .error = calendarImportStatus, calendarImportStep == .error(error) else {
				return
			}
			calendarImportStatus = .loading
			calendarImportStep = .checkingAuthorisation
		}
	}

	func performCalendarImport() async {
		do {
			Print("[iOS] Calendar Import: Starting authorization check...")
			moveForward(to: .checkingAuthorisation)

			let eventStore = EKEventStore()

			Print("[iOS] Calendar Import: Requesting calendar access...")
			moveForward(to: .requestionCalendarAccess)

			let authorized = try await eventStore.requestFullAccessToEvents()

			guard authorized else {
				errorAndExit("Calendar access denied")
				return
			}

			Print("[iOS] Calendar Import: Searching for Compass calendar...")
			moveForward(to: .findingCalendar)

			guard let calendar = eventStore.calendars(for: .event).first(where: {
				$0.title.range(of: "Compass", options: .caseInsensitive) != nil
			}) else {
				errorAndExit("Compass calendar not found")
				return
			}

			Print("[iOS] Calendar Import: Fetching events...")
			moveForward(to: .fetchingEvents)

			let events = try await fetchCompassEvents(from: eventStore, calendar: calendar)

			Print("[iOS] Calendar Import: Matching events to time slots...")
			moveForward(to: .matchingEvents)

			let importedSubjects = try await matchEventsToTimeSlots(events)

			Print("[iOS] Calendar Import: Processing subjects...")
			moveForward(to: .processingSubjects)
			let translatedSubjects = translateSubjects(importedSubjects)

			Print("[iOS] Calendar Import: Validating...")
			moveForward(to: .finalising)

			let updatedSubjects = translatedSubjects
				.sorted { $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending }
				.filter { !$0.slots.isEmpty }
			subjects = try await ServerSyncCoordinator.shared.saveOwnerTimetable(updatedSubjects)

			await prepareSubjectTagUpdate(for: updatedSubjects)

		} catch {
			errorAndExit(error.localizedDescription)
		}
	}

	private func prepareSubjectTagUpdate(for importedSubjects: [Subject]) async {
		do {
			async let catalogueRequest = administrationService.tagCatalogue()
			async let subscriptionsRequest = administrationService.tagSubscriptions()
			let (catalogue, subscriptions) = try await (catalogueRequest, subscriptionsRequest)

			let subjectTags = catalogue.sections
				.filter { $0.category == .subject }
				.flatMap(\.tags)
			let subjectTagIDs = Set(subjectTags.map(\.id))
			let currentSubjectTagIDs = Set(subscriptions.tagIDs).intersection(subjectTagIDs)
			let importedNames = Set(importedSubjects.map { normalizedImportedSubjectName($0.id) })
			let proposedSubjectTags = subjectTags.filter { tag in
				let associatedNames = tag.associatedNames + [tag.displayName]
				return associatedNames.contains { importedNames.contains(normalizedImportedSubjectName($0)) }
			}
			let proposedSubjectTagIDs = Set(proposedSubjectTags.map(\.id))

			guard proposedSubjectTagIDs != currentSubjectTagIDs else {
				completeImport(detail: "Your existing subject tags already match the imported timetable.")
				return
			}

			guard !currentSubjectTagIDs.isEmpty else {
				await applySubjectTagReplacement(proposedSubjectTagIDs)
				return
			}

			moveForward(to: .choosingSubjectTags)
			subjectTagProposal = SubjectTagReplacementProposal(
				proposedTagIDs: proposedSubjectTagIDs,
				currentTagNames: subjectTags
					.filter { currentSubjectTagIDs.contains($0.id) }
					.map(\.displayName)
					.sorted(),
				proposedTagNames: proposedSubjectTags
					.map(\.displayName)
					.sorted()
			)
		} catch {
			completeImport(detail: "The timetable was imported, but subject tags could not be checked. Your existing subscriptions were preserved.")
		}
	}

	private func keepCurrentSubjectTags() {
		subjectTagProposal = nil
		completeImport(detail: "The timetable was imported. Your existing subject tags were kept.")
	}

	private func replaceSubjectTags() {
		guard let subjectTagProposal else {
			return
		}

		isApplyingSubjectTags = true
		Task {
			await applySubjectTagReplacement(subjectTagProposal.proposedTagIDs)
		}
	}

	private func applySubjectTagReplacement(_ tagIDs: Set<UUID>) async {
		defer {
			isApplyingSubjectTags = false
			subjectTagProposal = nil
		}

		do {
			_ = try await administrationService.replaceSubjectTagSubscriptions(tagIDs)
			completeImport(detail: "The timetable and matching subject tags were imported.")
		} catch {
			completeImport(detail: "The timetable was imported, but subject tags could not be updated. Your existing subscriptions were preserved.")
		}
	}

	private func completeImport(detail: String) {
		moveForward(to: .done)
		Print("[iOS] Calendar Import: Success!")
		successDetail = detail
		calendarImportStatus = .success
		completion?(true)

		if dismissesWhenFinished {
			Task {
				try? await Task.sleep(for: .seconds(2))
				close()
			}
		}
	}
}

#Preview {
	Color.gray
		.ignoresSafeArea()
		.sheet(isPresented: .constant(true)) {
			CalendarImportView()
				.appPaperPresentation()
		}
}
