//
//   main sheet.swift
//   Main
//
//   Created by Adon Omeri on 25/4/2026.
//

import SwiftUI

struct SubjectEditorSheet: View {
	@Environment(\.dismiss) var dismiss
	@Environment(\.statusBadgeManager) private var statusBadgeManager

	@Binding var subjects: [Subject]

	@State private var editorPage = 0
	@State private var editorReady = false
	@State private var isSaving = false
	@State private var draftSubjects: [EditableSubject] = []
	@State private var pendingPrefillSlot: EditableSlot?
	@State private var pendingConflict: SlotConflict?
	@State private var renameTargetSubjectID: EditableSubject.ID?
	@State private var proposedSubjectName = ""
	@State private var symbolPickerSubjectID: EditableSubject.ID?

	let initialRequest: EditorRequest?
	let onSave: (([Subject]) async throws -> [Subject])?

	init(
		subjects: Binding<[Subject]>,
		initialRequest: EditorRequest?,
		onSave: (([Subject]) async throws -> [Subject])? = nil
	) {
		_subjects = subjects
		self.initialRequest = initialRequest
		self.onSave = onSave
	}

	var body: some View {
		NavigationStack {
			Group {
				if editorReady {
					SubjectEditorPager(
						draftSubjects: $draftSubjects,
						editorPage: $editorPage,
						pendingPrefillSlot: pendingPrefillSlot,
						isSaving: isSaving,
						dayLabel: dayLabel,
						allowedPeriods: { day in allowedPeriods(for: day) },
						canUse: { period, day in canUse(period: period, on: day) },
						addNewSubject: addNewSubject,
						deleteSubject: deleteSubject,
						beginRenamingSubject: beginRenamingSubject,
						selectSymbol: { symbolPickerSubjectID = $0 }
					)
				} else {
					ProgressView()
						.frame(maxWidth: .infinity, maxHeight: .infinity)
				}
			}
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel", systemImage: "xmark") {
						dismiss()
					}
					.keyboardShortcut(.cancelAction)
					.disabled(isSaving)
				}

				ToolbarItem(placement: .confirmationAction) {
					Button("Done", systemImage: "checkmark") {
						validateAndSave()
					}
					.disabled(isSaving)
				}
			}
		}
		.alert(
			"Rename Subject",
			isPresented: renameAlertPresented,
			actions: {
				TextField("Subject Name", text: $proposedSubjectName)

				Button("Cancel", role: .cancel) {
					renameTargetSubjectID = nil
					proposedSubjectName = ""
				}

				Button("Save") {
					applySubjectRename()
				}
			},
			message: {
				Text("Enter a new subject name.")
			}
		)
		.alert(
			"Slot Conflict",
			isPresented: conflictAlertPresented,
			actions: {
				if let conflict = pendingConflict {
					Button(conflict.firstSubjectName) {
						resolveConflict(keeping: conflict.firstSubjectName)
					}

					Button(conflict.secondSubjectName) {
						resolveConflict(keeping: conflict.secondSubjectName)
					}

					Button("Cancel", role: .cancel) {
						pendingConflict = nil
					}
				}
			},
			message: {
				if let conflict = pendingConflict {
					Text("Both \(conflict.firstSubjectName) and \(conflict.secondSubjectName) use \(slotLabel(conflict.slot)). Which one should keep it?")
				}
			}
		)
		.onAppear {
			prepareEditor()
		}
		.onDisappear {
			editorReady = false
		}
		.sheet(isPresented: symbolPickerPresented) {
			if let id = symbolPickerSubjectID {
				SymbolPickerSheet(
					subjectID: id,
					draftSubjects: $draftSubjects
				)
			}
		}
		#if os(iOS)
		.presentationDetents([.height(750), .large])
		.presentationDragIndicator(.hidden)
		.interactiveDismissDisabled()
		#endif
	}

	private var renameAlertPresented: Binding<Bool> {
		Binding(
			get: { renameTargetSubjectID != nil },
			set: { newValue in
				if !newValue {
					renameTargetSubjectID = nil
					proposedSubjectName = ""
				}
			}
		)
	}

	private var conflictAlertPresented: Binding<Bool> {
		Binding(
			get: { pendingConflict != nil },
			set: { newValue in
				if !newValue {
					pendingConflict = nil
				}
			}
		)
	}

	private var symbolPickerPresented: Binding<Bool> {
		Binding(
			get: { symbolPickerSubjectID != nil },
			set: { newValue in
				if !newValue {
					symbolPickerSubjectID = nil
				}
			}
		)
	}

	private func dayLabel(_ day: Int) -> String {
		TimetableLayout.fullDayLabels[day]
	}

	private func allowedPeriods(for day: Int) -> [Int] {
		TimetableLayout.allowedPeriods(for: day)
	}

	private func canUse(period: Int, on day: Int) -> Bool {
		TimetableLayout.canUse(period: period, on: day)
	}

	private func sessionForPeriod(_ period: Int) -> Int? {
		TimetableLayout.session(forPeriod: period)
	}

	private func periodForSession(_ session: Int) -> Int? {
		TimetableLayout.period(forSession: session)
	}

	private func slotLabel(_ slot: Slot) -> String {
		guard let period = periodForSession(slot.session) else {
			return dayLabel(slot.day)
		}

		return "\(dayLabel(slot.day)) Period \(period)"
	}

	private func addNewSubject() {
		let newSlot = pendingPrefillSlot ?? EditableSlot(day: 0, period: 1)

		draftSubjects.append(
			EditableSubject(
				originalName: nil,
				name: "New Subject",
				symbol: "book.closed",
				color: AvailableColors.sapphireVoid.SwiftUIColor,
				slots: [
					newSlot,
					EditableSlot(day: 0, period: 2),
					EditableSlot(day: 0, period: 3),
					EditableSlot(day: 0, period: 4),
				],
				classroom: "",
				teacher: ""
			)
		)

		pendingPrefillSlot = nil
		editorPage = draftSubjects.count - 1
	}

	private func deleteSubject(at index: Int) {
		guard draftSubjects.indices.contains(index) else { return }

		draftSubjects.remove(at: index)

		if editorPage > draftSubjects.count {
			editorPage = draftSubjects.count
		}
	}

	private func beginRenamingSubject(at index: Int) {
		guard draftSubjects.indices.contains(index) else { return }

		renameTargetSubjectID = draftSubjects[index].id
		proposedSubjectName = draftSubjects[index].name
	}

	private func applySubjectRename() {
		guard
			let renameTargetSubjectID,
			let index = draftSubjects.firstIndex(where: { $0.id == renameTargetSubjectID })
		else {
			renameTargetSubjectID = nil
			proposedSubjectName = ""
			return
		}

		draftSubjects[index].name = proposedSubjectName
		self.renameTargetSubjectID = nil
		proposedSubjectName = ""
	}

	private func resolveConflict(keeping keptSubjectName: String) {
		guard let conflict = pendingConflict else { return }

		let losingName = keptSubjectName == conflict.firstSubjectName
			? conflict.secondSubjectName
			: conflict.firstSubjectName

		guard
			let period = periodForSession(conflict.slot.session),
			let losingIndex = draftSubjects.firstIndex(where: { $0.name == losingName })
		else {
			pendingConflict = nil
			return
		}

		draftSubjects[losingIndex].slots.removeAll {
			$0.day == conflict.slot.day && $0.period == period
		}

		pendingConflict = nil

		if let nextConflict = firstConflict(in: draftSubjects) {
			pendingConflict = nextConflict
		} else {
			validateAndSave()
		}
	}

	private func firstConflict(in editableSubjects: [EditableSubject]) -> SlotConflict? {
		var seen: [Slot: String] = [:]

		for editableSubject in editableSubjects {
			for editableSlot in editableSubject.slots {
				guard let session = sessionForPeriod(editableSlot.period),
				      canUse(period: editableSlot.period, on: editableSlot.day)
				else { continue }

				let slot = Slot(editableSlot.day, session)

				if let existingSubjectName = seen[slot], existingSubjectName != editableSubject.name {
					return SlotConflict(
						slot: slot,
						firstSubjectName: existingSubjectName,
						secondSubjectName: editableSubject.name
					)
				}

				seen[slot] = editableSubject.name
			}
		}

		return nil
	}

	private func buildCommittedSubjects() -> [Subject] {
		draftSubjects.map { editableSubject in
			var uniqueSlots = Set<Slot>()

			for editableSlot in editableSubject.slots.prefix(4) {
				guard let session = sessionForPeriod(editableSlot.period),
				      canUse(period: editableSlot.period, on: editableSlot.day)
				else { continue }

				uniqueSlots.insert(Slot(editableSlot.day, session))
			}

			return Subject(
				id: editableSubject.name.trimmingCharacters(in: .whitespacesAndNewlines),
				symbol: editableSubject.symbol,
				colour: editableSubject.color.toRGBA(),
				slots: Array(uniqueSlots),
				classroom: Classroom(rawLocation: editableSubject.classroom),
				teacher: Teacher.editorValue(editableSubject.teacher)
			)
		}
	}

	private func commitToLocalModel(_ committedSubjects: [Subject]) {
		subjects = committedSubjects

		Task {
			await indexEntities()
		}
	}

	private func validateAndSave() {
		guard !isSaving else { return }

		let names = draftSubjects.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }

		if names.contains(where: \.isEmpty) {
			statusBadgeManager.addBadge(
				id: UUID(),
				title: "Subject name cannot be empty.",
				priority: 4,
				view: .error
			)
			return
		}

		if Set(names).count != names.count {
			statusBadgeManager.addBadge(
				id: UUID(),
				title: "Subject names must be unique.",
				priority: 4,
				view: .error
			)
			return
		}

		if let conflict = firstConflict(in: draftSubjects) {
			pendingConflict = conflict
			return
		}

		let proposedSubjects = buildCommittedSubjects()

		isSaving = true
		Task { @MainActor in
			defer { isSaving = false }

			do {
				let savedSubjects: [Subject] = if let onSave {
					try await onSave(proposedSubjects)
				} else {
					proposedSubjects
				}

				commitToLocalModel(savedSubjects)
				dismiss()
			} catch {
				// ServerSyncCoordinator already displays the sync errors.
				// Keep the sheet open and do not commit local Defaults.
			}
		}
	}

	private func prepareEditor() {
		editorReady = false

		switch initialRequest {
			case let .allSubjectes(focus):
				draftSubjects = makeDraftSubjects()
				pendingPrefillSlot = nil

				if let focus {
					if let index = draftSubjects.firstIndex(where: { $0.name == focus || $0.originalName == focus }) {
						Print("[iOS] Editor focus: found '\(focus)' at index \(index)")
						editorPage = index
					} else {
						PrintError("[iOS] Editor focus: '\(focus)' NOT FOUND, defaulting to 0. Available: \(draftSubjects.map(\.name).joined(separator: ", "))")
						editorPage = 0
					}
				} else {
					editorPage = 0
				}

			case let .emptySlot(prefill):
				draftSubjects = makeDraftSubjects()
				pendingPrefillSlot = prefill
				editorPage = draftSubjects.count

			case nil:
				draftSubjects = makeDraftSubjects()
				editorPage = 0
				pendingPrefillSlot = nil
		}

		editorReady = true
	}

	private func makeDraftSubjects() -> [EditableSubject] {
		subjects.map { original in
			EditableSubject(
				originalName: original.id,
				name: original.id,
				symbol: original.symbol,
				color: original.colour.swiftUIColor,
				slots: original.slots.compactMap { slot in
					guard let period = periodForSession(slot.session) else { return nil }
					return EditableSlot(day: slot.day, period: period)
				},
				classroom: original.classroom.editorValue,
				teacher: original.teacher.editorValue
			)
		}
	}
}
