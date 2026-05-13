//
//  TimetableView.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 13/5/2026.
//

import Defaults
import SwiftUI

struct TimetableView: View {
	@ObservedObject var watchSync: PhoneWatchSyncBridge

	@Default(.timetable) var classes
	@Default(.receivedTimetables) var receivedTimetables
	@Default(.userDisplayName) var userDisplayName
	@Default(.displayMode) var displayMode

	@State private var showingEditor = false
	@State private var editorRequest: EditorRequest?
	@State private var isEditMode = false
	@State private var selectedTimetableIndex: Int?
	@State private var showTimetableComparison = false
	@State private var selectedSlot: (day: Int, session: Int)? = nil

	@Binding var syncStatus: SyncMode

	var currentTimetable: [Class] {
		selectedTimetableIndex.flatMap { idx in
			receivedTimetables.indices.contains(idx) ? receivedTimetables[idx].classes : nil
		} ?? classes
	}

	var currentTimetableTitle: String {
		if let idx = selectedTimetableIndex {
			return "\(receivedTimetables[idx].sender)'s Timetable"
		}
		return "PMS Timetable"
	}

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: currentTimetable)

		NavigationStack {
			VStack {
				HStack(spacing: 4) {
					VStack(spacing: 4) {
						Text("")

						ForEach(TimetableLayout.sessions, id: \.self) { session in
							sessionLabel(for: session)
						}
						.frame(width: 25)
					}
					.frame(width: 25)

					mainContent(classLookup: classLookup)
				}

				Spacer(minLength: 1)
					.toolbar {
						ToolbarItem(placement: .topBarLeading) {
							Toggle(isOn: $isEditMode) {
								Image(systemName: "pencil")
									.foregroundStyle(.primary)
							}
						}

						ToolbarItem(placement: .principal) {
							Text(currentTimetableTitle)
								.monospaced()
								.contentTransition(.numericText())
						}

						if !receivedTimetables.isEmpty {
							ToolbarItem(placement: .topBarTrailing) {
								Menu {
									Button {
										selectedTimetableIndex = nil
									} label: {
										HStack {
											if selectedTimetableIndex == nil {
												Image(systemName: "checkmark")
											}
											Text("Your Timetable")
										}
									}

									if !receivedTimetables.isEmpty {
										Divider()

										ForEach(receivedTimetables.indices, id: \.self) { idx in
											Button {
												selectedTimetableIndex = idx
											} label: {
												HStack {
													if selectedTimetableIndex == idx {
														Image(systemName: "checkmark")
													}
													Text(receivedTimetables[idx].sender)
												}
											}
										}
									}
								} label: {
									Image(systemName: "person.2")
								}
							}
						} else if currentTimetable != defaultTimetable {
							ToolbarItem(placement: .topBarTrailing) {
								SyncButton(
									syncStatus: syncStatus,
									isDefaultTimetable: currentTimetable == defaultTimetable,
									action: {
										Task {
											await syncToWatchAsync(
												classes: currentTimetable,
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
				ClassEditorSheet(
					classes: $classes,
					initialRequest: editorRequest
				)
				.presentationDetents([.fraction(0.8)])
				.presentationDragIndicator(.visible)
				.interactiveDismissDisabled()
			}
			.sheet(isPresented: $showTimetableComparison) {
				timetableComparisonSheet
					.presentationDetents([.fraction(0.4)])
					.presentationDragIndicator(.hidden)
			}
		}
	}

	private var timetableComparisonSheet: some View {
		VStack(spacing: 20) {
			if let slot = selectedSlot,
			   let yourClass = getClassAtSlot(day: slot.day, session: slot.session, in: classes)
			{
				HStack {
					Text("You")
					Spacer()
					HStack(spacing: 8) {
						Image(systemName: yourClass.symbol)
							.font(.title3)
						Text(yourClass.id)
							.font(.body)
					}
				}
				.padding(10)
				.glassEffect(.clear.tint(yourClass.colour.swiftUIColor).interactive(), in: RoundedRectangle(cornerRadius: 12))

			} else {
				HStack {
					Text("You")
					Spacer()
					Text("Free period")
				}
				.padding(10)
				.glassEffect(.clear.tint(.gray).interactive(), in: RoundedRectangle(cornerRadius: 12))
			}

			Divider()

			Text("Other Timetables")
				.font(.title2)
				.padding(.top, 8)

			VStack(spacing: 8) {
				ForEach(receivedTimetables.indices, id: \.self) { idx in
					if let slot = selectedSlot,
					   let theirClass = getClassAtSlot(day: slot.day, session: slot.session, in: receivedTimetables[idx].classes)
					{
						HStack {
							Text(receivedTimetables[idx].sender)

							Spacer()

							HStack(spacing: 8) {
								Image(systemName: theirClass.symbol)
								Text(theirClass.id)
							}
						}
						.padding(10)
						.glassEffect(.clear.tint(theirClass.colour.swiftUIColor).interactive(), in: RoundedRectangle(cornerRadius: 12))

					} else {
						HStack {
							Text(receivedTimetables[idx].sender)

							Spacer()

							Text("Free period")
						}
						.padding(10)
						.glassEffect(.clear.tint(.gray).interactive(), in: RoundedRectangle(cornerRadius: 12))
					}
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)

			Spacer()
		}
		.padding()
	}

	private func findCurrentClass(in timetable: [Class]) -> Class? {
		let today = Date()
		let weekday = Calendar.current.component(.weekday, from: today)
		let dayIndex = (weekday + 5) % 7

		guard dayIndex < 5 else { return nil }

		let hour = Calendar.current.component(.hour, from: today)
		let minute = Calendar.current.component(.minute, from: today)
		let timeInMinutes = hour * 60 + minute

		let periodSchedule = [
			(8, 50, 9, 48), // Period 1
			(9, 48, 10, 46), // Period 2
			(11, 8, 12, 6), // Period 3
			(12, 6, 13, 4), // Period 4
			(13, 34, 14, 32), // Period 5
			(14, 32, 15, 30), // Period 6
		]

		for (sessionIndex, (startH, startM, endH, endM)) in periodSchedule.enumerated() {
			let startMinutes = startH * 60 + startM
			let endMinutes = endH * 60 + endM

			if timeInMinutes >= startMinutes, timeInMinutes < endMinutes {
				let classLookup = TimetableLayout.classLookup(for: timetable)
				return classLookup[Slot(dayIndex, sessionIndex)]
			}
		}
		return nil
	}

	private func getClassAtSlot(day: Int, session: Int, in timetable: [Class]) -> Class? {
		let classLookup = TimetableLayout.classLookup(for: timetable)
		return classLookup[Slot(day, session)]
	}

	func mainContent(classLookup: [Slot: Class]) -> some View {
		ForEach(0 ..< 5) { day in
			VStack(spacing: 4) {
				Text(TimetableLayout.shortDayLabels[day])
				ForEach(0 ..< 8) { session in
					sessionCell(day, session, classLookup: classLookup)
				}
			}
		}
	}

	func sessionCell(_ day: Int, _ session: Int, classLookup: [Slot: Class]) -> some View {
		Group {
			if TimetableLayout.isBreakSession(index: session) {
				rectangle(.gray.opacity(0.25), true)
					.frame(height: 20)
			} else {
				if TimetableLayout.isUnavailable(day: day, session: session) {
					rectangle(.clear, true)
						.frame(height: 60)

				} else {
					if let c = classLookup[Slot(day, session)] {
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
							if isEditMode {
								openEditor(focusingClassName: c.id)
							} else if !receivedTimetables.isEmpty {
								selectedSlot = (day, session)
								showTimetableComparison = true
							}
						}

					} else {
						RoundedRectangle(cornerRadius: 10)
							.fill(.white.opacity(0.05))
							.frame(height: 60)
							.onTapGesture {
								if isEditMode {
									openEditorForEmptySlot(day: day, session: session)
								} else if !receivedTimetables.isEmpty {
									showTimetableComparison = true
								}
							}
					}
				}
			}
		}
		.foregroundStyle(.white)
	}

	func sessionLabel(for session: String) -> some View {
		let isBreakSession = TimetableLayout.isBreakSession(label: session)

		return Text(session)
			.frame(height: isBreakSession ? 20 : 60)
			.foregroundStyle(isBreakSession ? Color.secondary : Color.primary)
	}

	func openEditor(focusingClassName className: String? = nil) {
		editorRequest = .allClasses(focus: className)
		showingEditor = true
	}

	func openEditorForEmptySlot(day: Int, session: Int) {
		guard let prefill = editableSlot(fromDay: day, session: session) else { return }
		editorRequest = .emptySlot(prefill)
		showingEditor = true
	}

	func editableSlot(fromDay day: Int, session: Int) -> EditableSlot? {
		guard
			let period = TimetableLayout.period(forSession: session),
			TimetableLayout.canUse(period: period, on: day)
		else { return nil }

		return EditableSlot(day: day, period: period)
	}
}
