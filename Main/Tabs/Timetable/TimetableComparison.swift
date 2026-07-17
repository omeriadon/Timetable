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

	@State private var presentedSubject: PresentedSubject?

	var body: some View {
		VStack(spacing: 14) {
			let friends = passManager.receivedTimetables.filter { $0.sourceKind != .accountOwner }
			if friends.isEmpty {
				#if os(iOS)
					ContentUnavailableView {
						Label {
							Text("No Friend Timetables")
						} icon: {
							Image(systemName: "person.2")
						}
						.font(.callout)
						.foregroundStyle(.secondary)
					} description: {
						Text("Import a friend's timetable to compare it with yours here.")
							.font(.caption)
					}
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
				#endif // os(iOS)
			} else {
				ForEach(friends) { timetable in
					ZStack {
						if let slot = selectedSlot,
						   let theirSubject = getSubjectAtSlot(day: slot.day, session: slot.session, in: timetable.subjects)
						{
							Button {
								presentedSubject = PresentedSubject(
									owner: timetable.sender,
									subject: theirSubject
								)
							} label: {
								item(
									left: Text(timetable.sender),
									right: Label(theirSubject.id, systemImage: theirSubject.symbol),
									colour: theirSubject.colour.swiftUIColor
								)
								.tint(.white)
							}
							.buttonStyle(.plain)
							.popover(item: $presentedSubject) { presented in
								SubjectContextPopover(
									owner: presented.owner,
									subject: presented.subject
								)
								.presentationCompactAdaptation(.popover)
							}
						} else {
							item(
								left: Text(timetable.sender),
								right: Label("Free period", systemImage: "square.dotted"),
								colour: .gray
							)
						}
					}
				}
			}

			Spacer()
		}
		.padding()
	}

	private func getSubjectAtSlot(day: Int, session: Int, in timetable: [Subject]) -> Subject? {
		let subjectLookup = TimetableLayout.subjectLookup(for: timetable)
		return subjectLookup[Slot(day, session)]
	}
}

private struct PresentedSubject: Identifiable {
	let id = UUID()
	let owner: String
	let subject: Subject
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
	.glassEffect(.clear.tint(colour).interactive(), in: top ? AnyShape(RoundedRectangle(cornerRadius: 30)) : AnyShape(Capsule()))
	.contentShape(Rectangle())
}
