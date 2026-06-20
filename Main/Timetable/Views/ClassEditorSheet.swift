//
//  ClassEditorSheet.swift
//  Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import SFSymbolsPicker
import SwiftUI

struct ClassEditorSheet: View {
	@Environment(\.dismiss) var dismiss

	@Binding var classes: [Class]

	@State private var editorPage = 0
	@State private var editorReady = false

	let initialRequest: EditorRequest?

	@State private var draftClasses: [EditableClass] = []
	@State private var pendingPrefillSlot: EditableSlot?
	@State private var pendingConflict: SlotConflict?
	@State private var validationMessage: String?
	@State private var renameTargetClassID: EditableClass.ID?
	@State private var proposedClassName = ""
	@State private var symbolPickerClassID: EditableClass.ID?

	var body: some View {
		NavigationStack {
			VStack {
				if editorReady {
					TabView(selection: $editorPage) {
						ForEach(Array(draftClasses.enumerated()), id: \.element.id) { index, draftClass in
							Tab(draftClass.name, systemImage: draftClass.symbol, value: index) {
								classEditorPage(index: index)
							}
						}

						Tab("Add Class", systemImage: "plus", value: draftClasses.count) {
							addClassPage
						}
					}
					#if os(iOS)
					.tabViewStyle(.page(indexDisplayMode: .always))
					#else
					.tabViewStyle(.sidebarAdaptable)
					#endif
					.animation(.snappy, value: draftClasses.count)
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
			"Rename Class",
			isPresented: renameAlertPresented,
			actions: {
				TextField("Class Name", text: $proposedClassName)
				Button("Cancel", role: .cancel) {
					renameTargetClassID = nil
					proposedClassName = ""
				}
				Button("Save") {
					applyClassRename()
				}
			},
			message: {
				Text("Enter a new class name.")
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
					Button(conflict.firstClassName) {
						resolveConflict(keeping: conflict.firstClassName)
					}
					Button(conflict.secondClassName) {
						resolveConflict(keeping: conflict.secondClassName)
					}
					Button("Cancel", role: .cancel) {
						pendingConflict = nil
					}
				}
			},
			message: {
				if let conflict = pendingConflict {
					Text("Both \(conflict.firstClassName) and \(conflict.secondClassName) use \(slotLabel(conflict.slot)). Which one should keep it?")
				}
			}
		)
		.alert(
			"Invalid Class Name",
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
			if let id = symbolPickerClassID {
				symbolPickerSheet(for: id)
			}
		}
	}

	func classEditorPage(index: Int) -> some View {
		VStack(spacing: 15) {
			classHeaderRow(index: index)
			symbolSelectionRow(index: index)

			InlineColorPicker(selectedColor: selectedColorBinding(for: draftClasses[index].id))

			slotEditorSection(index: index)
				.animation(.spring(response: 0.3, dampingFraction: 0.8), value: draftClasses[index].slots)

			Spacer()
		}
		#if os(iOS)
		.padding(.horizontal, 32)
		#else
		.padding(.horizontal, 20)
		.padding(.top, 10)
		#endif
	}

	var addClassPage: some View {
		VStack(spacing: 16) {
			Spacer()
			Button {
				withAnimation {
					addNewClass()
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

			Text("Add New Class")
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

	func addNewClass() {
		let newSlot = pendingPrefillSlot ?? EditableSlot(day: 0, period: 1)
		draftClasses.append(
			EditableClass(
				originalName: nil,
				name: "New Class",
				symbol: "book.closed",
				color: AvailableColors.sapphireVoid.SwiftUIColor,
				slots: [newSlot, EditableSlot(day: 0, period: 2), EditableSlot(day: 0, period: 3), EditableSlot(day: 0, period: 4)]
			)
		)
		pendingPrefillSlot = nil
		editorPage = draftClasses.count - 1
	}

	func addSlot(to index: Int) {
		guard draftClasses.indices.contains(index), draftClasses[index].slots.count < 4 else { return }
		draftClasses[index].slots.append(EditableSlot(day: 0, period: 1))
	}

	func deleteClass(at index: Int) {
		guard draftClasses.indices.contains(index) else { return }
		draftClasses.remove(at: index)
		if editorPage > draftClasses.count {
			editorPage = draftClasses.count
		}
	}

	func resolveConflict(keeping keptClassName: String) {
		guard let conflict = pendingConflict else { return }
		let losingName = keptClassName == conflict.firstClassName ? conflict.secondClassName : conflict.firstClassName

		guard
			let period = periodForSession(conflict.slot.session),
			let losingIndex = draftClasses.firstIndex(where: { $0.name == losingName })
		else {
			pendingConflict = nil
			return
		}

		draftClasses[losingIndex].slots.removeAll {
			$0.day == conflict.slot.day && $0.period == period
		}
		pendingConflict = nil

		if let nextConflict = firstConflict(in: draftClasses) {
			pendingConflict = nextConflict
		} else {
			commitDraftToModel()
			dismiss()
		}
	}

	func commitDraftToModel() {
		classes = draftClasses.map { editableClass in
			var uniqueSlots = Set<Slot>()
			for editableSlot in editableClass.slots.prefix(4) {
				guard let session = sessionForPeriod(editableSlot.period),
				      canUse(period: editableSlot.period, on: editableSlot.day)
				else { continue }
				uniqueSlots.insert(Slot(editableSlot.day, session))
			}

			return Class(
				id: editableClass.name.trimmingCharacters(in: .whitespacesAndNewlines),
				symbol: editableClass.symbol,
				colour: editableClass.color.toRGBA(),
				slots: Array(uniqueSlots)
			)
		}
	}

	func validateAndSave() {
		let names = draftClasses.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
		if names.contains(where: \.isEmpty) {
			validationMessage = "Class name cannot be empty."
			return
		}
		if Set(names).count != names.count {
			validationMessage = "Class names must be unique."
			return
		}
		if let conflict = firstConflict(in: draftClasses) {
			pendingConflict = conflict
			return
		}
		commitDraftToModel()
		dismiss()
	}

	func firstConflict(in editableClasses: [EditableClass]) -> SlotConflict? {
		var seen: [Slot: String] = [:]

		for editableClass in editableClasses {
			for editableSlot in editableClass.slots {
				guard let session = sessionForPeriod(editableSlot.period),
				      canUse(period: editableSlot.period, on: editableSlot.day)
				else { continue }

				let slot = Slot(editableSlot.day, session)

				if let existingClassName = seen[slot], existingClassName != editableClass.name {
					return SlotConflict(
						slot: slot,
						firstClassName: existingClassName,
						secondClassName: editableClass.name
					)
				}
				seen[slot] = editableClass.name
			}
		}
		return nil
	}

	func prepareEditor() {
		editorReady = false

		switch initialRequest {
			case let .allClasses(focus):
				draftClasses = makeDraftClasses()
				pendingPrefillSlot = nil

				if let focus {
					if let index = draftClasses.firstIndex(where: { $0.name == focus || $0.originalName == focus }) {
						print("[iOS] Editor focus: found '\(focus)' at index \(index)")
						editorPage = index
					} else {
						print("[iOS] Editor focus: '\(focus)' NOT FOUND, defaulting to 0. Available: \(draftClasses.map(\.name).joined(separator: ", "))")
						editorPage = 0
					}
				} else {
					editorPage = 0
				}

			case let .emptySlot(prefill):
				draftClasses = makeDraftClasses()
				pendingPrefillSlot = prefill
				editorPage = draftClasses.count

			case nil:
				draftClasses = makeDraftClasses()
				editorPage = 0
				pendingPrefillSlot = nil
		}

		editorReady = true
	}

	func makeDraftClasses() -> [EditableClass] {
		classes.map { original in
			EditableClass(
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
			get: { renameTargetClassID != nil },
			set: { newValue in
				if !newValue {
					renameTargetClassID = nil
					proposedClassName = ""
				}
			}
		)
	}

	var symbolPickerPresented: Binding<Bool> {
		Binding(
			get: { symbolPickerClassID != nil },
			set: { newValue in
				if !newValue {
					symbolPickerClassID = nil
				}
			}
		)
	}

	func symbolPickerSheet(for id: EditableClass.ID) -> some View {
		SymbolsPicker(
			selection: selectedSymbolBinding(for: id),
			title: "",
			searchLabel: "Search symbols...",
			autoDismiss: true
		)
	}

	func classHeaderRow(index: Int) -> some View {
		GlassEffectContainer(spacing: 0) {
			HStack(alignment: .center) {
				Button {
					beginRenamingClass(at: index)
				} label: {
					HStack(spacing: 0) {
						Text(draftClasses[index].name.isEmpty ? "Class Name" : draftClasses[index].name)
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
						.fill(draftClasses[index].color.opacity(0.22))
						.animation(.snappy(duration: 0.25), value: draftClasses[index].color)
				}
				.glassEffect(
					.clear.tint(draftClasses[index].color).interactive(),
					in: Capsule()
				)
				.animation(.snappy(duration: 0.25), value: closestColor(to: draftClasses[index].color))

				Button(role: .destructive) {
					withAnimation {
						deleteClass(at: index)
					}
				} label: {
					Label("Delete Class", systemImage: "trash")
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
			symbolPickerClassID = draftClasses[index].id
		} label: {
			HStack {
				Image(systemName: draftClasses[index].symbol)
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
			ForEach($draftClasses[index].slots) { $slot in
				slotRow(slot: $slot, classIndex: index)
					.transition(.scale.combined(with: .opacity))
			}

			if draftClasses[index].slots.count < 4 {
				Button {
					draftClasses[index].slots.append(
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

	func slotRow(slot: Binding<EditableSlot>, classIndex: Int) -> some View {
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
				draftClasses[classIndex].slots.removeAll { $0.id == slot.wrappedValue.id }
			} label: {
				Image(systemName: "trash")
			}
			.frame(width: 20)
			.buttonStyle(.glassProminent)
			.buttonBorderShape(.circle)
		}
	}

	func beginRenamingClass(at index: Int) {
		guard draftClasses.indices.contains(index) else { return }
		renameTargetClassID = draftClasses[index].id
		proposedClassName = draftClasses[index].name
	}

	func applyClassRename() {
		guard
			let renameTargetClassID,
			let index = draftClasses.firstIndex(where: { $0.id == renameTargetClassID })
		else {
			renameTargetClassID = nil
			proposedClassName = ""
			return
		}

		draftClasses[index].name = proposedClassName
		self.renameTargetClassID = nil
		proposedClassName = ""
	}

	func selectedSymbolBinding(for classID: EditableClass.ID) -> Binding<String> {
		Binding(
			get: {
				draftClasses.first(where: { $0.id == classID })?.symbol ?? "questionmark"
			},
			set: { newValue in
				guard let index = draftClasses.firstIndex(where: { $0.id == classID }) else { return }
				draftClasses[index].symbol = newValue
			}
		)
	}

	func selectedColorBinding(for classID: EditableClass.ID) -> Binding<AvailableColors> {
		Binding(
			get: {
				guard let editableClass = draftClasses.first(where: { $0.id == classID }) else {
					return .sapphireVoid
				}
				return closestColor(to: editableClass.color)
			},
			set: { newValue in
				guard let index = draftClasses.firstIndex(where: { $0.id == classID }) else { return }
				draftClasses[index].color = newValue.SwiftUIColor
			}
		)
	}
}
