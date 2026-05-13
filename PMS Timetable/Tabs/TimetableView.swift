//
//  TimetableView.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SFSymbolsPicker
import SwiftUI

struct TimetableView: View {
	@State var watchSync: PhoneWatchSyncBridge
	@Default(.timetable) var classes
	@Default(.receivedTimetables) var receivedTimetables
	@Default(.displayMode) var displayMode

	@State private var showingEditor = false
	@State private var editorRequest: EditorRequest?
	@State private var editorReady = false
	@State private var draftClasses: [EditableClass] = []
	@State private var editorPage = 0
	@State private var pendingPrefillSlot: EditableSlot?
	@State private var pendingConflict: SlotConflict?
	@State private var validationMessage: String?
	@State private var isPresented = false

	@Binding var syncStatus: SyncMode

	var body: some View {
		NavigationStack {
			VStack {
				HStack(spacing: 4) {
					VStack(spacing: 4) {
						Text("")

						ForEach(Array(sessions.enumerated()), id: \.offset) { _, session in
							if session == "R" || session == "L" {
								Text(session)
									.frame(height: 20)
									.foregroundStyle(.secondary)
							} else {
								Text(session)
									.frame(height: 60)
							}
						}
						.frame(width: 25)
					}
					.frame(width: 25)

					mainContent
				}

				Spacer(minLength: 1)

					.padding(.horizontal, 3)
					.toolbar {
						ToolbarItem(placement: .topBarLeading) {
							Button {
								openEditor()
							} label: {
								Label("Edit", systemImage: "pencil")
							}
						}

						ToolbarItem(placement: .principal) {
							Text("PMS Timetable")
								.monospaced()
						}

						if classes != defaultTimetable {
							ToolbarItem(placement: .topBarTrailing) {
								SyncButton(
									syncStatus: syncStatus,
									isDefaultTimetable: classes == defaultTimetable,
									action: {
										Task {
											await syncToWatchAsync(
												classes: classes,
												displayMode: displayMode,
												watchSync: watchSync,
												statusUpdate: { syncStatus = $0 }
											)
										}
									}
								)
							}
						}
					}
					.navigationBarTitleDisplayMode(.inline)
			}
			.environment(\.dynamicTypeSize, .xSmall)
			.monospaced()
			.onAppear {
				watchSync.activateIfNeeded()
				watchSync.updateLatestClasses(classes)
			}
			.onChange(of: classes) { _, newValue in
				watchSync.updateLatestClasses(newValue)
			}
			.onChange(of: watchSync.lastError) { _, newValue in
				guard let newValue else { return }
				print("[iOS] Surface error icon: \(newValue)")
				syncStatus = .error
				Task {
					try? await Task.sleep(nanoseconds: 1_000_000_000)
					await MainActor.run {
						syncStatus = .normal
					}
				}
				watchSync.lastError = nil
			}
			.sheet(isPresented: $showingEditor) {
				editorSheet
					.presentationDetents([.fraction(0.8)])
					.presentationDragIndicator(.visible)
					.interactiveDismissDisabled()
					.onAppear {
						prepareEditor()
					}
					.onDisappear {
						editorRequest = nil
						editorReady = false
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
		}
	}

	var mainContent: some View {
		ForEach(0 ..< 5) { day in
			VStack(spacing: 4) {
				Text(["Mon", "Tue", "Wed", "Thu", "Fri"][day])
				ForEach(0 ..< 8) { session in
					sessionCell(day, session)
				}
			}
		}
	}

	func sessionCell(_ day: Int, _ session: Int) -> some View {
		Group {
			if session == 2 || session == 5 {
				rectangle(.gray.opacity(0.25), true)
					.frame(height: 20)
			} else {
				if day == 2 && session == 7 || day == 4 && session == 7 {
					rectangle(.clear, true)
						.frame(height: 60)

				} else {
					if let c = classFor(day: day, session: session) {
						rectangle(
							c.colour.swiftUIColor.opacity(0.8)
						) {
							Image(systemName: c.symbol)
							Spacer(minLength: 0)
							Text(c.id)
								.lineLimit(2)
								.fixedSize(horizontal: false, vertical: true)
								.font(.footnote.scaled(by: 0.9))
						}
						.frame(height: 60)
						.onTapGesture {
							openEditor(focusingClassName: c.id)
						}

					} else {
						RoundedRectangle(cornerRadius: 10)
							.fill(.white.opacity(0.05))
							.frame(height: 60)
							.onTapGesture {
								openEditorForEmptySlot(day: day, session: session)
							}
					}
				}
			}
		}
		.foregroundStyle(.white)
	}

	var editorSheet: some View {
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
						showingEditor = false
					}
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Done", systemImage: "checkmark") {
						validateAndSave()
					}
				}
			}
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
					Text("Select Symbol")
						.padding(.leading, 10)
					Spacer()
					Image(systemName: draftClasses[index].symbol)
						.imageScale(.large)
						.sheet(
							isPresented: $isPresented,
							content: {
								SymbolsPicker(
									selection: $draftClasses[index].symbol,
									title: "Select Symbol",
									autoDismiss: true
								)
							}
						).padding()
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

	func classFor(day: Int, session: Int) -> Class? {
		classes.first { c in
			c.slots.contains {
				$0.day == day && $0.session == session
			}
		}
	}

	func openEditor(focusingClassName className: String? = nil) {
		editorRequest = .allClasses(focus: className)
		presentEditor()
	}

	func openEditorForEmptySlot(day: Int, session: Int) {
		guard let prefill = editableSlot(fromDay: day, session: session) else { return }
		editorRequest = .emptySlot(prefill)
		presentEditor()
	}

	func presentEditor() {
		if showingEditor { return }
		showingEditor = true
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
		showingEditor = false
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
			showingEditor = false
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

	func editableSlot(fromDay day: Int, session: Int) -> EditableSlot? {
		guard let period = periodForSession(session), canUse(period: period, on: day) else { return nil }
		return EditableSlot(day: day, period: period)
	}

	func slotLabel(_ slot: Slot) -> String {
		guard let period = periodForSession(slot.session) else { return "\(dayLabel(slot.day))" }
		return "\(dayLabel(slot.day)) Period \(period)"
	}
}
