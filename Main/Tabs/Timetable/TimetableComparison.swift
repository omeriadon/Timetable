//
//   TimetableComparison.swift
//   Main
//
//   Created by Adon Omeri on 11/6/2026.
//

import Defaults
import SwiftUI
import TipKit

struct TimetableComparison: View {
	@Default(.friends) private var friends

	let selectedSlot: Slot?
	let subject: Subject?

	@State private var presentedSubject: PresentedSubject?

	let tip = WeekTapFriendTip()

	var body: some View {
		VStack(spacing: 14) {
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
						Text("Add a friend to compare their timetable with yours here.")
							.font(.caption)
					}
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
				#endif // os(iOS)
			} else {
				ForEach(friends) { friend in
					if let timetable = friend.timetable {
						ZStack {
							if let slot = selectedSlot,
							   let theirSubject = getSubjectAtSlot(day: slot.day, session: slot.session, in: timetable.subjects)
							{
								Button {
									presentedSubject = PresentedSubject(
										owner: friend.friend.displayName,
										subject: theirSubject
									)
									tip.invalidate(reason: .actionPerformed)
								} label: {
									item(
										left: Text(friend.friend.displayName),
										right: Label(theirSubject.id, systemImage: theirSubject.symbol),
										colour: theirSubject.colour.swiftUIColor
									)
									.tint(.white)
								}
								.buttonStyle(.plain)
							} else {
								item(
									left: Text(friend.friend.displayName),
									right: Label("Free period", systemImage: "square.dotted"),
									colour: .gray
								)
							}
						}
					}
				}
				.popoverTip(tip, attachmentAnchor: .point(.bottom), arrowEdges: .bottom)
			}

			Spacer()
		}
		.padding()
		.popover(item: $presentedSubject) { presented in
			SubjectContextPopover(
				owner: presented.owner,
				subject: presented.subject
			)
			.presentationCompactAdaptation(.popover)
		}
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
			.contentTransition(.numericText())
			.frame(height: top ? 40 : 20)
			.padding(.trailing, 5)
	}
	.padding(15)
	.glassEffect(.clear.tint(colour).interactive(), in: top ? AnyShape(RoundedRectangle(cornerRadius: 30)) : AnyShape(Capsule()))
	.contentShape(Rectangle())
}
