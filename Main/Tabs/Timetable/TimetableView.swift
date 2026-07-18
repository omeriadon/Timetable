//
//   TimetableView.swift
//   Main
//
//   Created by Adon Omeri on 11/6/2026.
//

import Defaults
import SwiftUI

extension Notification.Name {
	static let openTimetableDestination = Notification.Name("openTimetableDestination")
}

struct TimetableView: View {
	#if os(iOS)
		@Binding var watchSync: PhoneWatchSyncBridge
		@Binding var syncStatus: SyncMode
	#else
		@Binding var expanded: WindowMode
	#endif

	@Default(.timetable) var subjects
	@Default(.timetableHighlightsCurrentDay) private var highlightsCurrentDay

	@Default(.receivedTimetables) private var receivedTimetables

	@State private var selectedTimetable: ReceivedTimetable?
	@State private var showTimetableComparison = false
	@State private var selectedSlot: Slot? = nil

	#if os(iOS)
		init(
			watchSync: Binding<PhoneWatchSyncBridge>,
			syncStatus: Binding<SyncMode>,
			startComparisonOpen: Bool = false
		) {
			_watchSync = watchSync
			_syncStatus = syncStatus
			_showTimetableComparison = State(initialValue: startComparisonOpen)
		}
	#else
		init(
			expanded: Binding<WindowMode>,
			startComparisonOpen: Bool = false
		) {
			_expanded = expanded
			_showTimetableComparison = State(initialValue: startComparisonOpen)
		}

		var currentTimetableTitle: String {
			if let timetable = selectedTimetable {
				return "\(timetable.sender)'s Timetable"
			}
			return "Timetable"
		}
	#endif

	var body: some View {
		let subjectLookup = TimetableLayout.subjectLookup(for: selectedTimetable?.subjects ?? subjects)

		NavigationStack {
			VStack {
				ScrollView {
					let subject: Subject? = if let selectedSlot, let subject = subjectLookup[selectedSlot] {
						subject
					} else {
						nil
					}

					VStack {
						if let subject {
							let rightView = VStack(alignment: .leading) {
								Label {
									switch subject.classroom {
										case let .room(building, floor, number):
											let secondaryText = if let floor {
												"\(floor.displayName) \(building.displayName)"
											} else {
												building.displayName
											}

											HStack(spacing: 10) {
												Text(secondaryText)
													.textCase(.uppercase)
													.foregroundStyle(.secondary)

												Text(number.description)
													.font(.headline)
													.bold()
											}

										case let .unknown(rawLocation):
											Text(rawLocation)
									}

								} icon: {
									Image(systemName: "door.left.hand.open")
								}

								Label(subject.teacher.displayName, systemImage: "person.fill")
							}

							let leftView = VStack(alignment: .leading) {
								Text("You")
									.textCase(.uppercase)
									.foregroundStyle(.secondary)
								Label(subject.id, systemImage: subject.symbol)
							}

							item(left: leftView, right: rightView, colour: subject.colour.swiftUIColor, top: true)
								.padding(.horizontal, 10)
								.id(subject.id)
								.transition(.blurReplace)
								.animation(.spring(.bouncy), value: subject.id)
						}

						Spacer()
							.frame(height: 10)

						TimetableComparison(selectedSlot: selectedSlot, subject: subject)
							.opacity(selectedSlot == nil ? 0 : 1)
							.blur(radius: selectedSlot == nil ? 20 : 0)
							.allowsHitTesting(selectedSlot != nil)
							.animation(.snappy(duration: 0.3), value: selectedSlot)
					}
				}
				.scrollIndicators(.visible)
				#if os(macOS)
					.opacity(selectedSlot != nil ? 1 : 0)
					.scrollIndicatorsFlash(onAppear: true)
				#endif // os(macOS)
					.opacity(selectedSlot == nil ? 0 : 1)
					.safeAreaBar(edge: .top, alignment: .center, spacing: 10) {
						GlassEffectContainer(spacing: 2) {
							HStack(spacing: 4) {
								VStack(spacing: 4) {
									Text("")

									ForEach(TimetableLayout.sessions, id: \.self) { session in
										sessionLabel(for: session)
									}
								}
								.frame(width: 15)

								mainContent(subjectLookup: subjectLookup)
									.drawingGroup(opaque: false)
							}
						}
						.padding(.bottom, Device.isMacOS ? 7 : 10)
						#if os(macOS)
							.padding([.top, .horizontal], 10)
						#endif
					}
					.scrollEdgeEffectStyle(.soft, for: .bottom)
					.scrollEdgeEffectStyle(.none, for: .top)
			}
			#if os(iOS)
			.onAppear {
				watchSync.activateIfNeeded()
			}
			#else
			.onChange(of: selectedSlot) {
						if selectedSlot == nil {
							expanded = .none
						} else {
							expanded = .comparison
						}
					}
					.onAppear {
						if selectedSlot != nil {
							expanded = .comparison
						}
					}
			#endif
		}
		.padding(.trailing, 2)
		.dynamicTypeSize(.medium)
		.onReceive(NotificationCenter.default.publisher(for: .openTimetableTab)) { _ in
			selectedSlot = nil
		}
		.onReceive(NotificationCenter.default.publisher(for: .openTimetableDestination)) { notification in
			guard let destination = notification.object as? TimetableDeepLink else { return }
			switch destination {
				case let .timetable(id):
					selectedTimetable = id.flatMap { received in receivedTimetables.first { $0.id == received && !$0.isDeleted } }
					selectedSlot = nil
				case let .subject(timetableID, subjectID, slot):
					selectedTimetable = timetableID.flatMap { received in receivedTimetables.first { $0.id == received && !$0.isDeleted } }
					let subjects = selectedTimetable?.subjects ?? subjects
					selectedSlot = slot ?? subjects.first(where: { $0.id == subjectID })?.slots.first
			}
		}
	}

	private func findCurrentSubject(in timetable: [Subject]) -> Subject? {
		guard case let .lesson(lesson) = SchoolStateEngine.calculate(
			at: TimetableClock.now,
			subjects: timetable
		) else {
			return nil
		}

		return lesson.subject
	}

	func mainContent(subjectLookup: [Slot: Subject]) -> some View {
		ForEach(0 ..< 5) { day in
			VStack(spacing: 4) {
				Text(TimetableLayout.shortDayLabels[day])
				ForEach(0 ..< 8) { session in
					SessionCellView(day, session, subjectLookup, selectedSlot)
						.contentShape(Rectangle())
						.onTapGesture {
							withAnimation(.snappy(duration: 0.3)) {
								if selectedSlot == Slot(day, session) {
									selectedSlot = nil
								} else if subjectLookup[Slot(day, session)] != nil {
									selectedSlot = Slot(day, session)
								}
							}
						}
				}
			}
			.background {
				if highlightsCurrentDay, currentDayIndex == day {
					RoundedRectangle(cornerRadius: 8)
						.stroke(.white, lineWidth: 2)
						.padding(-2)
				}
			}
		}
	}

	private var currentDayIndex: Int? {
		let weekday = Calendar.current.component(.weekday, from: TimetableClock.now)
		guard (2 ... 6).contains(weekday) else { return nil }
		return weekday - 2
	}

	func sessionLabel(for session: String) -> some View {
		let isBreakSession = TimetableLayout.isBreakSession(label: session)

		return Text(session)
			.frame(height: isBreakSession ? TimetableLayout.breakCellHeight : TimetableLayout.sessionCellHeight)
			.foregroundStyle(isBreakSession ? Color.clear : Color.primary)
	}

	func editableSlot(fromDay day: Int, session: Int) -> EditableSlot? {
		guard
			let period = TimetableLayout.period(forSession: session),
			TimetableLayout.canUse(period: period, on: day)
		else { return nil }

		return EditableSlot(day: day, period: period)
	}
}
