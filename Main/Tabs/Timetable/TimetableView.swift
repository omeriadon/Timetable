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
	@Environment(AppRouter.self) private var router
	@Environment(\.appPresentation) private var presentation
	#if os(iOS) && !targetEnvironment(macCatalyst)
		@State private var watchSync = PhoneWatchSyncBridge.shared
	#elseif os(macOS)
		@Binding var expanded: WindowMode
	#endif

	@Default(.timetable) var subjects
	@Default(.accountSettings) private var accountSettings
	@Default(.schoolCalendar) private var schoolCalendar
	@Default(.calendarEvents) private var calendarEvents

	@Default(.receivedTimetables) private var receivedTimetables

	@State private var selectedTimetable: ReceivedTimetable?
	@State private var showTimetableComparison = false
	@State private var selectedSlot: Slot? = nil
	@State private var schoolCalendarSync = SchoolCalendarSyncService.shared
	@State private var calendarEventsSync = CalendarEventsSyncService.shared

	@State private var currentTab: Int = 0
	@State private var scrollPosition: Int?

	#if os(iOS)
		init(
			startComparisonOpen: Bool = false
		) {
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
		ScrollView(.horizontal) {
			HStack(spacing: 0) {
				TodayTimetableView(
					subjects: selectedTimetable?.subjects ?? subjects
				)
				.containerRelativeFrame(.horizontal)
				.scrollEdgeEffect(direction: .clearTopDarkBottom, offset: 0.9, maxBlurRadius: 1, maximumOpacity: 0.7)
				.scrollEdgeEffect(offset: 0.9, maxBlurRadius: 4, maximumOpacity: 0.7)
				.id(0)

				mainView
					.containerRelativeFrame(.horizontal)
					.scrollEdgeEffect(direction: .clearTopDarkBottom, offset: 0.9, maxBlurRadius: 1, maximumOpacity: 0.7)
					.scrollEdgeEffect(offset: 0.9, maxBlurRadius: 6, maximumOpacity: 1)
					.id(1)

				DatesView()
					.containerRelativeFrame(.horizontal)
					.scrollEdgeEffect(direction: .clearTopDarkBottom, offset: 0.9, maxBlurRadius: 1, maximumOpacity: 0.7)
					.id(2)
			}
			.scrollTargetLayout()
		}
		.scrollTargetBehavior(.paging)
		.scrollIndicators(.hidden)
		.scrollPosition(id: $scrollPosition)
		.safeAreaBar(edge: .top, alignment: .center, spacing: 0) {
			TabsPicker(
				items: [
					("Today", "calendar.day.timeline.left"),
					("Week", "7.calendar"),
					("Planner", "pencil.and.list.clipboard"),
				],
				selection: $currentTab
			)
			.padding(.horizontal, 10)
			.frame(height: 36)
			.padding(.bottom, 5)
		}
		.onChange(of: currentTab) { _, newValue in
			withAnimation {
				scrollPosition = newValue
			}
			refreshCalendarData()
		}
		.onChange(of: scrollPosition) { _, newValue in
			if let newValue {
				currentTab = newValue
			}
		}
	}

	private func refreshCalendarData() {
		Task {
			async let schoolCalendarRefresh: Void = schoolCalendarSync.downloadCalendar()
			async let calendarEventsRefresh: Void = calendarEventsSync.downloadEvents()
			_ = try? await (schoolCalendarRefresh, calendarEventsRefresh)
		}
	}

	private var mainView: some View {
		let subjectLookup = TimetableLayout.subjectLookup(for: selectedTimetable?.subjects ?? subjects)

		return NavigationStack {
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
													.contentTransition(.numericText())

												Text(number.description)
													.font(.headline)
													.bold()
													.contentTransition(.numericText())
											}

										case let .unknown(rawLocation):
											Text(rawLocation)
									}

								} icon: {
									Image(systemName: "door.left.hand.open")
										.contentTransition(.numericText())
								}

								Label(subject.teacher.displayName, systemImage: "person.fill")
									.contentTransition(.numericText())
							}

							let leftView = VStack(alignment: .leading) {
								Text("YOU")
									.foregroundStyle(.secondary)
									.contentTransition(.numericText())
								Label(subject.id, systemImage: subject.symbol)
									.contentTransition(.numericText())
							}

							item(left: leftView, right: rightView, colour: subject.colour.swiftUIColor, top: true)
								.padding(.horizontal, 10)
								.padding(.top, 5)
								.transition(.opacity)
								.animation(.spring(.bouncy), value: subject.id)
								.foregroundStyle(.white)
								.padding(.horizontal, Device.isIPad ? 10 : 0)
						}

						Spacer()
							.frame(height: 10)

						TimetableComparison(selectedSlot: selectedSlot, subject: subject)
							.opacity(selectedSlot == nil ? 0 : 1)
							.blur(radius: selectedSlot == nil ? 20 : 0)
							.allowsHitTesting(selectedSlot != nil)
							.animation(.snappy(duration: 0.3), value: selectedSlot)
							.padding(.horizontal, Device.isIPad ? 10 : 0)
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
							.background {
								ZStack {
									Color.black.opacity(0.5)
									#if os(iOS)
										BlurView(blurRadius: 10)
									#else
										Color.clear
									#endif
								}
							}
					}
					.scrollEdgeEffectStyle(.soft, for: .top)
			}
			.padding(.trailing, 2)
			.dynamicTypeSize(.medium)
			.onReceive(NotificationCenter.default.publisher(for: .openTimetableTab)) { _ in
				selectedSlot = nil
			}
			.onReceive(NotificationCenter.default.publisher(for: .openTimetableDestination)) { notification in
				guard let route = notification.object as? AppRoute,
				      case let .timetable(destination) = route
				else {
					return
				}
				switch destination {
					case .root:
						selectedTimetable = nil
						selectedSlot = nil
					case let .received(id):
						selectedTimetable = receivedTimetables.first { $0.id == id && !$0.isDeleted }
						selectedSlot = nil
					case let .subject(timetableID, subjectID, slot):
						selectedTimetable = timetableID.flatMap { received in receivedTimetables.first { $0.id == received && !$0.isDeleted } }
						let subjects = selectedTimetable?.subjects ?? subjects
						selectedSlot = slot ?? subjects.first(where: { $0.id == subjectID })?.slots.first
					case .planner, .calendarEvent:
						break
				}
			}
			.onChange(of: selectedSlot) { _, slot in
				guard presentation != .iOS else {
					return
				}
				guard let slot,
				      let subject = subjectLookup[slot]
				else {
					if case .some(.timetable) = router.inspectorRoute {
						router.inspectorRoute = nil
					}
					return
				}
				router.navigate(
					to: .timetable(
						.subject(
							timetableID: selectedTimetable?.id,
							subjectID: subject.id,
							slot: slot
						)
					)
				)
			}
			#if os(iOS)
				#if !targetEnvironment(macCatalyst)
					.onAppear {
						watchSync.activateIfNeeded()
					}
				#endif
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
	}

	private func findCurrentSubject(in timetable: [Subject]) -> Subject? {
		guard case let .lesson(lesson) = SchoolStateEngine.calculate(
			at: TimetableClock.now,
			subjects: timetable,
			calendar: SchoolCalendarProjection.perthCalendar,
			schoolCalendar: schoolCalendar
		) else {
			return nil
		}

		return lesson.subject
	}

	func mainContent(subjectLookup: [Slot: Subject]) -> some View {
		ForEach(0 ..< 5) { day in
			VStack(spacing: 4) {
				Text(TimetableLayout.shortDayLabels[day])
					.padding(.top, 3)
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
			.overlay {
				if accountSettings.highlightsCurrentDay, currentDayIndex == day {
					ZStack {
						RoundedRectangle(cornerRadius: 12, style: .continuous)
							.fill(.white.opacity(0.1))
							.strokeBorder(.white, lineWidth: 2)
							.blur(radius: 5)
							.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
						RoundedRectangle(cornerRadius: 12, style: .continuous)
							.fill(.white.opacity(0.1))
							.strokeBorder(.white, lineWidth: 2)
					}

					.allowsHitTesting(false)
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
