//
//   TimetableComparison.swift
//   Main
//
//   Created by Adon Omeri on 11/6/2026.
//

import SwiftUI

struct TimetableComparison: View {
	@Environment(\.passManager) private var passManager

	let selectedSlot: Slot?

	let subject: Subject?

	var body: some View {
		VStack(spacing: 8) {
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
										.font(.subheadline)
								}

							case let .unknown(rawLocation):
								Text(rawLocation)
						}

					} icon: {
						Image(systemName: "door.left.hand.open")
					}

					Label(subject.teacher.displayName, systemImage: "person.fill")
				}
				.padding(.horizontal, 8)

				let leftView = VStack(alignment: .leading) {
					Text("You")
						.textCase(.uppercase)
						.font(.callout)
					Label(subject.id, systemImage: subject.symbol)
				}

				item(left: leftView, right: rightView, colour: subject.colour.swiftUIColor, top: true)
			}

			Spacer()
				.frame(height: 15)

			ForEach(passManager.receivedTimetables.indices, id: \.self) { idx in
				ZStack {
					if let slot = selectedSlot,
					   let theirSubject = getSubjectAtSlot(day: slot.day, session: slot.session, in: passManager.receivedTimetables[idx].subjects)
					{
						Button {} label: {
							item(
								left: Text(passManager.receivedTimetables[idx].sender),
								right: Label(theirSubject.id, systemImage: theirSubject.symbol),
								colour: theirSubject.colour.swiftUIColor
							)
						}
						.buttonStyle(.plain)
						.contextMenu(menuItems: {}) {
							VStack {
								VStack(spacing: 6) {
									Text(passManager.receivedTimetables[idx].sender)
										.textCase(.uppercase)
										.foregroundStyle(.secondary)
										.lineLimit(1)
									Label(theirSubject.id, systemImage: theirSubject.symbol)
										.font(.subheadline)
										.lineLimit(2)
								}
								VStack {
									Label {
										switch theirSubject.classroom {
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
														.font(.subheadline)
												}

											case let .unknown(rawLocation):
												Text(rawLocation)
										}

									} icon: {
										Image(systemName: "door.left.hand.open")
									}

									Label(theirSubject.teacher.displayName, systemImage: "person.fill")
								}
							}
							.ignoresSafeArea()
							.padding(10)
							.background(theirSubject.colour.swiftUIColor)
						}

					} else {
						item(
							left: Text(passManager.receivedTimetables[idx].sender),
							right: Label("Free period", systemImage: "square.dotted"),
							colour: .gray
						)
					}
				}
			}

			Spacer()
		}
		.padding()
	}

	func item(
		left: some View,
		right: some View,
		colour: Color,
		top: Bool = false
	) -> some View {
		HStack {
			left

			Spacer()

			right
				.frame(height: top ? 40 : 20)
				.padding(.trailing, 5)
		}
		.padding(15)
		.glassEffect(.clear.tint(colour).interactive(), in: top ? AnyShape(RoundedRectangle(cornerRadius: 25)) : AnyShape(Capsule()))
	}

	private func getSubjectAtSlot(day: Int, session: Int, in timetable: [Subject]) -> Subject? {
		let subjectLookup = TimetableLayout.subjectLookup(for: timetable)
		return subjectLookup[Slot(day, session)]
	}
}
