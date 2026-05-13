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
	@Default(.displayMode) var displayMode

	@State private var showingEditor = false
	@State private var editorRequest: EditorRequest?

	@Binding var syncStatus: SyncMode

	var body: some View {
		let classLookup = TimetableLayout.classLookup(for: classes)

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
				ClassEditorSheet(
					classes: $classes,
					initialRequest: editorRequest
				)
				.presentationDetents([.fraction(0.8)])
				.presentationDragIndicator(.visible)
				.interactiveDismissDisabled()
			}
		}
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
