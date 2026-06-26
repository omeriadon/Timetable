//
//  SubjectEditorSheet.swift
//  Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import SFSymbolsPicker
import SwiftUI

struct SubjectEditorSheet: View {
	@Environment(\.dismiss) var dismiss

	@Binding var subjects: [Subject]

	@State private var editorPage = 0
	@State private var editorReady = false

	let initialRequest: EditorRequest?

	@State private var draftSubjects: [EditableSubject] = []
	@State private var pendingPrefillSlot: EditableSlot?
	@State private var pendingConflict: SlotConflict?
	@State private var validationMessage: String?
	@State private var renameTargetSubjectID: EditableSubject.ID?
	@State private var proposedSubjectName = ""
	@State private var symbolPickerSubjectID: EditableSubject.ID?

	var body: some View {
		NavigationStack {
			VStack {
				if editorReady {
					TabView(selection: $editorPage) {
						ForEach(Array(draftSubjects.enumerated()), id: \.element.id) { index, draftSubject in
							Tab(draftSubject.name, systemImage: draftSubject.symbol, value: index) {
								subjectEditorPage(index: index)
							}
						}

						Tab("Add Subject", systemImage: "plus", value: draftSubjects.count) {
							addSubjectPage
						}
					}
					#if os(iOS)
					.tabViewStyle(.page(indexDisplayMode: .always))
					#else
					.tabViewStyle(.sidebarAdaptable)
					#endif
					.animation(.snappy, value: draftSubjects.count)
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
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Done", systemImage: "checkmark") {
						validateAndSave()
					}
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
			isPresented: Binding(
				get: { pendingConflict != nil },
				set: { newValue in
					if !newValue {
						pendingConflict = nil
					}
				}
			),
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
		.alert(
			"Invalid Subject Name",
			isPresented: Binding(
				get: { validationMessage != nil },
				set: { newValue in
					if !newValue {
						validationMessage = nil
					}
				}
			),
			actions: {
				Button("OK", role: .cancel) {
					validationMessage = nil
				}
			},
			message: {
				Text(validationMessage ?? "")
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
				symbolPickerSheet(for: id)
			}
		}
	}

	func subjectEditorPage(index: Int) -> some View {
		VStack(spacing: 15) {
			subjectHeaderRow(index: index)
			symbolSelectionRow(index: index)

			InlineColorPicker(selectedColor: selectedColorBinding(for: draftSubjects[index].id))

			slotEditorSection(index: index)
				.animation(.spring(response: 0.3, dampingFraction: 0.8), value: draftSubjects[index].slots)

			Spacer()
		}
		#if os(iOS)
		.padding(.horizontal, 32)
		#else
		.padding(.horizontal, 20)
		.padding(.top, 10)
		#endif
	}

	var addSubjectPage: some View {
		VStack(spacing: 16) {
			Spacer()
			Button {
				withAnimation {
					addNewSubject()
				}
			} label: {
				ZStack {
					RoundedRectangle(cornerRadius: 24)
						.fill(.white.opacity(0.08))
						.frame(width: 180, height: 180)
					Image(systemName: "plus")
						.font(.system(size: 48, weight: .semibold))
				}
			}
			.buttonStyle(.plain)

			Text("Add New Subject")
				.font(.headline)
			if let pendingPrefillSlot {
				Text("Will prefill \(dayLabel(pendingPrefillSlot.day)) Period \(pendingPrefillSlot.period)")
					.foregroundStyle(.secondary)
			}
			Spacer()
		}
	}

	func dayLabel(_ day: Int) -> String {
		TimetableLayout.fullDayLabels[day]
	}

	func allowedPeriods(for day: Int) -> [Int] {
		TimetableLayout.allowedPeriods(for: day)
	}

	func canUse(period: Int, on day: Int) -> Bool {
		TimetableLayout.canUse(period: period, on: day)
	}

	func sessionForPeriod(_ period: Int) -> Int? {
		TimetableLayout.session(forPeriod: period)
	}

	func periodForSession(_ session: Int) -> Int? {
		TimetableLayout.period(forSession: session)
	}

	func slotLabel(_ slot: Slot) -> String {
		guard let period = periodForSession(slot.session) else { return "\(dayLabel(slot.day))" }
		return "\(dayLabel(slot.day)) Period \(period)"
	}

	func addNewSubject() {
		let newSlot = pendingPrefillSlot ?? EditableSlot(day: 0, period: 1)
		draftSubjects.append(
			EditableSubject(
				originalName: nil,
				name: "New Subject",
				symbol: "book.closed",
				color: AvailableColors.sapphireVoid.SwiftUIColor,
				slots: [newSlot, EditableSlot(day: 0, period: 2), EditableSlot(day: 0, period: 3), EditableSlot(day: 0, period: 4)]
			)
		)
		pendingPrefillSlot = nil
		editorPage = draftSubjects.count - 1
	}

	func addSlot(to index: Int) {
		guard draftSubjects.indices.contains(index), draftSubjects[index].slots.count < 4 else { return }
		draftSubjects[index].slots.append(EditableSlot(day: 0, period: 1))
	}

	func deleteSubject(at index: Int) {
		guard draftSubjects.indices.contains(index) else { return }
		draftSubjects.remove(at: index)
		if editorPage > draftSubjects.count {
			editorPage = draftSubjects.count
		}
	}

	func resolveConflict(keeping keptSubjectName: String) {
		guard let conflict = pendingConflict else { return }
		let losingName = keptSubjectName == conflict.firstSubjectName ? conflict.secondSubjectName : conflict.firstSubjectName

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
			commitDraftToModel()
			dismiss()
		}
	}

	func commitDraftToModel() {
		subjects = draftSubjects.map { EditableSubject in
			var uniqueSlots = Set<Slot>()
			for editableSlot in EditableSubject.slots.prefix(4) {
				guard let session = sessionForPeriod(editableSlot.period),
				      canUse(period: editableSlot.period, on: editableSlot.day)
				else { continue }
				uniqueSlots.insert(Slot(editableSlot.day, session))
			}

			return Subject(
				id: EditableSubject.name.trimmingCharacters(in: .whitespacesAndNewlines),
				symbol: EditableSubject.symbol,
				colour: EditableSubject.color.toRGBA(),
				slots: Array(uniqueSlots)
			)
		}

		Task {
			await indexEntities()
		}
	}

	func validateAndSave() {
		let names = draftSubjects.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
		if names.contains(where: \.isEmpty) {
			validationMessage = "Subject name cannot be empty."
			return
		}
		if Set(names).count != names.count {
			validationMessage = "Subject names must be unique."
			return
		}
		if let conflict = firstConflict(in: draftSubjects) {
			pendingConflict = conflict
			return
		}
		commitDraftToModel()
		dismiss()
	}

	func firstConflict(in EditableSubjectes: [EditableSubject]) -> SlotConflict? {
		var seen: [Slot: String] = [:]

		for EditableSubject in EditableSubjectes {
			for editableSlot in EditableSubject.slots {
				guard let session = sessionForPeriod(editableSlot.period),
				      canUse(period: editableSlot.period, on: editableSlot.day)
				else { continue }

				let slot = Slot(editableSlot.day, session)

				if let existingSubjectName = seen[slot], existingSubjectName != EditableSubject.name {
					return SlotConflict(
						slot: slot,
						firstSubjectName: existingSubjectName,
						secondSubjectName: EditableSubject.name
					)
				}
				seen[slot] = EditableSubject.name
			}
		}
		return nil
	}

	func prepareEditor() {
		editorReady = false

		switch initialRequest {
			case let .allSubjectes(focus):
				draftSubjects = makedraftSubjects()
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
				draftSubjects = makedraftSubjects()
				pendingPrefillSlot = prefill
				editorPage = draftSubjects.count

			case nil:
				draftSubjects = makedraftSubjects()
				editorPage = 0
				pendingPrefillSlot = nil
		}

		editorReady = true
	}

	func makedraftSubjects() -> [EditableSubject] {
		subjects.map { original in
			EditableSubject(
				originalName: original.id,
				name: original.id,
				symbol: original.symbol,
				color: original.colour.swiftUIColor,
				slots: original.slots.compactMap { slot in
					guard let period = periodForSession(slot.session) else { return nil }
					return EditableSlot(day: slot.day, period: period)
				}
			)
		}
	}

	var renameAlertPresented: Binding<Bool> {
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

	var symbolPickerPresented: Binding<Bool> {
		Binding(
			get: { symbolPickerSubjectID != nil },
			set: { newValue in
				if !newValue {
					symbolPickerSubjectID = nil
				}
			}
		)
	}

	func symbolPickerSheet(for id: EditableSubject.ID) -> some View {
		SymbolsPicker(
			selection: selectedSymbolBinding(for: id),
			title: "",
			searchLabel: "Search symbols...",
			autoDismiss: true
		)
	}

	func subjectHeaderRow(index: Int) -> some View {
		GlassEffectContainer(spacing: 0) {
			HStack(alignment: .center) {
				Button {
					beginRenamingSubject(at: index)
				} label: {
					HStack(spacing: 0) {
						Text(draftSubjects[index].name.isEmpty ? "Subject Name" : draftSubjects[index].name)
							.font(.title)
							.padding(10)
							.padding(.leading, 8)
							.contentTransition(.numericText())
							.lineLimit(1)

						Spacer(minLength: 0)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.contentShape(Capsule())
				}
				.buttonStyle(.plain)
				.background {
					Capsule()
						.fill(draftSubjects[index].color.opacity(0.22))
						.animation(.snappy(duration: 0.25), value: draftSubjects[index].color)
				}
				.glassEffect(
					.clear.tint(draftSubjects[index].color).interactive(),
					in: Capsule()
				)
				.animation(.snappy(duration: 0.25), value: closestColor(to: draftSubjects[index].color))

				Button(role: .destructive) {
					withAnimation {
						deleteSubject(at: index)
					}
				} label: {
					Label("Delete Subject", systemImage: "trash")
						.font(.title3)
						.padding(10)
						.labelStyle(.iconOnly)
				}
				.buttonStyle(.plain)
				.buttonBorderShape(.circle)
				.glassEffect(.clear.tint(.red).interactive(), in: Circle())
			}
			.padding(.top, 10)
		}
	}

	func symbolSelectionRow(index: Int) -> some View {
		Button {
			symbolPickerSubjectID = draftSubjects[index].id
		} label: {
			HStack {
				Image(systemName: draftSubjects[index].symbol)
					.font(.title2)

				Spacer()

				Text("Select Symbol")
					.padding(.trailing, 4)
			}
			.padding(10)
			.foregroundStyle(.white)
			.glassEffect(.clear.interactive(), in: Capsule())
			.frame(height: 25)
			.contentShape(.capsule)
		}
		.buttonStyle(.plain)
	}

	func slotEditorSection(index: Int) -> some View {
		VStack(alignment: .leading) {
			ForEach($draftSubjects[index].slots) { $slot in
				slotRow(slot: $slot, subjectIndex: index)
					.transition(.scale.combined(with: .opacity))
			}

			if draftSubjects[index].slots.count < 4 {
				Button {
					draftSubjects[index].slots.append(
						EditableSlot(day: 0, period: TimetableLayout.allowedPeriods(for: 0).first ?? 1)
					)
				} label: {
					Label("Add Slot", systemImage: "plus")
				}
				.buttonStyle(.glass)
				.buttonBorderShape(.capsule)
			}
		}
	}

	func slotRow(slot: Binding<EditableSlot>, subjectIndex: Int) -> some View {
		HStack {
			Picker("Day:", selection: slot.day) {
				ForEach(0 ..< 5, id: \.self) { day in
					Text(dayLabel(day)).tag(day)
				}
			}
			.tint(.white)
			.frame(width: 140, alignment: .leading)
			.pickerStyle(.menu)
			.onChange(of: slot.wrappedValue.day) { _, newDay in
				if !canUse(period: slot.wrappedValue.period, on: newDay) {
					slot.wrappedValue.period = 5
				}
			}

			Spacer()

			Picker("Period:", selection: slot.period) {
				ForEach(allowedPeriods(for: slot.wrappedValue.day), id: \.self) { period in
					Text("\(period)").tag(period)
				}
			}
			.frame(width: 140)
			.pickerStyle(.menu)

			Spacer()

			Button(role: .destructive) {
				draftSubjects[subjectIndex].slots.removeAll { $0.id == slot.wrappedValue.id }
			} label: {
				Image(systemName: "trash")
			}
			.frame(width: 20)
			.buttonStyle(.glassProminent)
			.buttonBorderShape(.circle)
		}
	}

	func beginRenamingSubject(at index: Int) {
		guard draftSubjects.indices.contains(index) else { return }
		renameTargetSubjectID = draftSubjects[index].id
		proposedSubjectName = draftSubjects[index].name
	}

	func applySubjectRename() {
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

	func selectedSymbolBinding(for subjectID: EditableSubject.ID) -> Binding<String> {
		Binding(
			get: {
				draftSubjects.first(where: { $0.id == subjectID })?.symbol ?? "questionmark"
			},
			set: { newValue in
				guard let index = draftSubjects.firstIndex(where: { $0.id == subjectID }) else { return }
				draftSubjects[index].symbol = newValue
			}
		)
	}

	func selectedColorBinding(for subjectID: EditableSubject.ID) -> Binding<AvailableColors> {
		Binding(
			get: {
				guard let EditableSubject = draftSubjects.first(where: { $0.id == subjectID }) else {
					return .sapphireVoid
				}
				return closestColor(to: EditableSubject.color)
			},
			set: { newValue in
				guard let index = draftSubjects.firstIndex(where: { $0.id == subjectID }) else { return }
				draftSubjects[index].color = newValue.SwiftUIColor
			}
		)
	}
}
