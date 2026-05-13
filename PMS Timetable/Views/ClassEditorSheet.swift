//
//  ClassEditorSheet.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import SFSymbolsPicker
import SwiftUI

struct ClassEditorSheet: View {
	@Environment(\.dismiss) var dismiss

	@Binding var classes: [Class]

	@State private var editorPage = 0
	@State private var isPresented = false
	@State private var editorReady = false

	let initialRequest: EditorRequest? = nil

	@State private var editorRequest: EditorRequest?
	@State private var draftClasses: [EditableClass] = []
	@State private var pendingPrefillSlot: EditableSlot?
	@State private var pendingConflict: SlotConflict?
	@State private var validationMessage: String?

	var body: some View {
		NavigationStack {
			Group {
				if editorReady {
					TabView(selection: $editorPage) {
						ForEach(draftClasses.indices, id: \.self) { index in
							ScrollView {
								classEditorPage(index: index)
							}
							.scrollBounceBehavior(.basedOnSize)
							.tag(index)
						}
						addClassPage
							.tag(draftClasses.count)
					}
					.tabViewStyle(.page(indexDisplayMode: .always))
					.animation(.snappy, value: draftClasses.count)
				} else {
					ProgressView()
						.frame(maxWidth: .infinity, maxHeight: .infinity)
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel", systemImage: "xmark") {
						dismiss()
					}
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Done", systemImage: "checkmark") {
						validateAndSave()
					}
				}
			}
		}
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
			editorRequest = nil
			editorReady = false
		}
	}

	func classEditorPage(index: Int) -> some View {
		VStack(spacing: 15) {
			GlassEffectContainer(spacing: 0) {
				HStack {
					TextField("Class Name", text: $draftClasses[index].name)
						.font(.title)
						.textFieldStyle(.plain)
						.padding(10)
						.padding(.leading, 8)
						.glassEffect(
							.clear.tint(draftClasses[index].color).interactive(),
							in: Capsule()
						)

					Button(role: .destructive) {
						withAnimation {
							deleteClass(at: index)
						}
					} label: {
						Label("Delete Class", systemImage: "trash")
							.font(.title)
							.padding(10)
							.labelStyle(.iconOnly)
					}
					.buttonStyle(.plain)
					.buttonBorderShape(.circle)
					.glassEffect(.clear.tint(.red).interactive(), in: Circle())
				}
			}

			Button {
				isPresented.toggle()
			} label: {
				HStack {
					Image(systemName: draftClasses[index].symbol)
						.font(.title)
						.sheet(
							isPresented: $isPresented,
							content: {
								SymbolsPicker(
									selection: $draftClasses[index].symbol,
									title: "",
									autoDismiss: true
								)
							}
						)
						.padding()

					Spacer()

					Text("Select Symbol")
						.padding(.trailing, 24)
				}
				.foregroundStyle(.white)
				.glassEffect(.clear.interactive(), in: Capsule())
			}

			InlineColorPicker(
				selectedColor: Binding<AvailableColors>(
					get: {
						closestColor(to: draftClasses[index].color)
					},
					set: { newEnum in
						draftClasses[index].color = newEnum.SwiftUIColor
					}
				)
			)

			VStack(alignment: .leading) {
				ForEach($draftClasses[index].slots) { $slot in
					HStack {
						Picker("Day:", selection: $slot.day) {
							ForEach(0 ..< 5, id: \.self) { day in
								Text("\(dayLabel(day))").tag(day)
							}
						}
						.frame(width: 140, alignment: .leading)
						.pickerStyle(.menu)
						.onChange(of: slot.day) { _, newDay in
							if !canUse(period: slot.period, on: newDay) {
								slot.period = 5
							}
						}

						Spacer()

						Picker("Period:", selection: $slot.period) {
							ForEach(allowedPeriods(for: slot.day), id: \.self) { period in
								Text("Period \(period)").tag(period)
							}
						}
						.frame(width: 140)
						.pickerStyle(.menu)

						Spacer()

						Button(role: .destructive) {
							// 1. Just mutate the array directly, no withAnimation block
							draftClasses[index].slots.removeAll { $0.id == slot.id }
						} label: {
							Image(systemName: "trash")
						}
						.frame(width: 20)
						.buttonStyle(.glassProminent)
						.buttonBorderShape(.circle)
					}
					// 2. Combine scale with opacity so it doesn't get aggressively clipped by the layout
					.transition(.scale.combined(with: .opacity))
				}

				if $draftClasses[index].slots.count < 4 {
					Button {
						// 3. Just mutate the array directly, no withAnimation block
						draftClasses[index].slots
							.append(EditableSlot(day: 0, period: allowedPeriods(for: 0).first ?? 1))
					} label: {
						Label("Add Slot", systemImage: "plus")
					}
					.buttonStyle(.glass)
					.buttonBorderShape(.capsule)
				}
			}
			// 4. THE MAGIC BULLET: This forces the VStack to animate ANY structural changes to this specific array.
			.animation(.spring(response: 0.3, dampingFraction: 0.8), value: draftClasses[index].slots)

			Spacer()
		}
		.padding(.horizontal, 32)
		.monospaced()
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
		["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"][day]
	}

	func allowedPeriods(for day: Int) -> [Int] {
		(day == 2 || day == 4) ? Array(1 ... 5) : Array(1 ... 6)
	}

	func canUse(period: Int, on day: Int) -> Bool {
		!(period == 6 && (day == 2 || day == 4))
	}

	func sessionForPeriod(_ period: Int) -> Int? {
		switch period {
			case 1: 0
			case 2: 1
			case 3: 3
			case 4: 4
			case 5: 6
			case 6: 7
			default: nil
		}
	}

	func periodForSession(_ session: Int) -> Int? {
		switch session {
			case 0: 1
			case 1: 2
			case 3: 3
			case 4: 4
			case 6: 5
			case 7: 6
			default: nil
		}
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
				color: .blue,
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

		switch editorRequest {
			case let .allClasses(focus):
				draftClasses = classes.map { original in
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
				draftClasses = classes.map { original in
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
				pendingPrefillSlot = prefill
				editorPage = draftClasses.count

			case nil:
				draftClasses = classes.map { original in
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
				editorPage = 0
				pendingPrefillSlot = nil
		}

		editorReady = true
	}
}
