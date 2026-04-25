//
//  ContentView.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import Defaults
import SwiftUI

enum EditMode: Equatable {
	case idle
	case placing(String)
}

struct ContentView: View {
	let sessions = [
		"1",
		"2",
		"R",
		"3",
		"4",
		"L",
		"5",
		"6",
	]

	@Default(.timetable) var classes

	@State private var mode: EditMode = .idle

	@State private var pendingSlot: Slot?
	@State private var showingConflict = false

	@State var showEditPopover: Class?

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
				Spacer()
			}
			.padding(.horizontal, 3)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button {
						if case .placing = mode {
							withAnimation {
								mode = .idle
							}
						}
					} label: {
						Label("Edit", systemImage: "square.and.pencil")
							.foregroundStyle(
								mode == EditMode.idle ? .secondary : .primary
							)
					}
				}

				ToolbarItem(placement: .topBarLeading) {
					Button {
						if case .placing(let c) = mode,
						   let classToDelete = classById(c)
						{
							deleteClass(classToDelete)
							withAnimation {
								mode = .idle
							}
						}
					} label: {
						Label("Delete", systemImage: "trash")
							.foregroundStyle(mode == .idle ? Color.secondary : Color.red)
					}
					.disabled(mode == .idle)
				}

				ToolbarItem(placement: .principal) {
					Text("PMS Timetable")
						.monospaced()
				}

				ToolbarItem(placement: .topBarTrailing) {
					Button {} label: {
						Label("Sync", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
					}
					.buttonStyle(.glassProminent)
				}
			}
			.navigationBarTitleDisplayMode(.inline)
		}
		.environment(\.dynamicTypeSize, .xSmall)
		.monospaced()
	}

	var mainContent: some View {
		ForEach(0..<5) { day in
			VStack(spacing: 4) {
				Text(["Mon", "Tue", "Wed", "Thu", "Fri"][day])
				ForEach(0..<8) { session in
					sessionCell(day, session)
				}
			}
		}
	}

	@ViewBuilder
	func sessionCell(_ day: Int, _ session: Int) -> some View {
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
					.alert(item: $showEditPopover) { c in
						Alert(
							title: Text(c.id),
							primaryButton: .default(Text("Copy")) {
								withAnimation {
									mode = .placing(c.id)
								}
							},
							secondaryButton: .cancel()
						)
					}
					.onTapGesture {
						guard case .placing(let id) = mode,
						      let c = classById(id)
						else {
							showEditPopover = c
							return
						}

						let slot = Slot(day, session)

						if classFor(day: day, session: session) != nil {
							pendingSlot = slot
							showingConflict = true
						} else {
							place(c, at: slot)
						}
					}
					.alert("Overwrite slot?", isPresented: $showingConflict) {
						Button("Replace", role: .destructive) {
							if let slot = pendingSlot,
							   case .placing(let c) = mode,
							   let classToOverwrite = classById(c)
							{
								place(classToOverwrite, at: slot)
							}

							pendingSlot = nil
							mode = .idle
						}

						Button("Cancel", role: .cancel) {
							pendingSlot = nil
						}
					}

				} else {
					RoundedRectangle(cornerRadius: 0)
						.fill(
							LinearGradient(
								stops: [
									.init(color: .red, location: 0),
									.init(color: .blue, location: 0.5),
									.init(color: .red, location: 1),
								],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.frame(height: 60)
				}
			}
		}
	}

	func classFor(day: Int, session: Int) -> Class? {
		classes.first { c in
			c.slots.contains {
				$0.day == day && $0.session == session
			}
		}
	}

	func deleteClass(_ c: Class) {
		classes.removeAll { $0.id == c.id }
	}

	func place(_ c: Class, at slot: Slot) {
		if let i = classes.firstIndex(where: { $0.id == c.id }) {
			classes[i].slots.append(slot)
		}
	}

	func classById(_ id: String) -> Class? {
		classes.first { $0.id == id }
	}
}

struct rectangle<Content: View>: View {
	let fill: Color
	let isBreak: Bool
	let content: Content

	init(
		_ fill: Color,
		_ isBreak: Bool = false,
		@ViewBuilder content: () -> Content
	) {
		self.fill = fill
		self.isBreak = isBreak
		self.content = content()
	}

	init(_ fill: Color, _ isBreak: Bool = false) where Content == EmptyView {
		self.fill = fill
		self.isBreak = isBreak
		self.content = EmptyView()
	}

	var body: some View {
		VStack(alignment: .leading) {
			content
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		}
		.padding(5)
		.glassEffect(
			!isBreak ? .clear.tint(fill) /* .interactive() */ : .identity,
			in: RoundedRectangle(cornerRadius: isBreak ? 8 : 10)
		)
	}
}

#Preview {
	ContentView()
}
