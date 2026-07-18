//
//   ShareSelectionSheet.swift
//   Main
//
//   Created by Codex on 02/07/2026.
//

import Defaults
import SwiftUI

enum SelectedShareItem: Identifiable, Hashable {
	case owner(id: UUID)
	case authored(id: UUID, name: String)
	case received(id: String, name: String)

	var id: String {
		switch self {
			case let .owner(id): "owner-\(id.uuidString)"
			case let .authored(id, _): "authored-\(id.uuidString)"
			case let .received(id, _): "received-\(id)"
		}
	}
}

struct ShareSelectionSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Default(.ownerIsSearchable) var ownerIsSearchable
	@Default(.receivedTimetables) var receivedTimetables
	@State private var authoredTimetableService = AuthoredTimetableService.shared

	let onSelect: (SelectedShareItem) -> Void

	var body: some View {
		NavigationStack {
			List {
				if ownerIsSearchable, let ownerID = UUID(uuidString: Defaults[.ownerTimetableID]) {
					Section("Your Timetable") {
						Button {
							dismiss()
							onSelect(.owner(id: ownerID))
						} label: {
							HStack {
								Text(verbatim: Defaults[.accountProfile].map { "\($0.displayName)'s Timetable" } ?? "Your Timetable")
									.foregroundStyle(.primary)
								Spacer()
								Image(systemName: "person.crop.circle")
									.foregroundStyle(.secondary)
							}
						}
					}
				}

				let authored = authoredTimetableService.timetables.filter(\.isSearchable)
				if !authored.isEmpty {
					Section("Authored Timetables") {
						ForEach(authored) { timetable in
							Button {
								dismiss()
								onSelect(.authored(id: timetable.id, name: timetable.title))
							} label: {
								HStack {
									Text(timetable.title)
										.foregroundStyle(.primary)
									Spacer()
									Image(systemName: "calendar")
										.foregroundStyle(.secondary)
								}
							}
						}
					}
				}

				let received = receivedTimetables.filter { $0.isShareable && $0.sourceKind != .accountOwner }
				if !received.isEmpty {
					Section("Saved Timetables") {
						ForEach(received) { timetable in
							Button {
								dismiss()
								onSelect(.received(id: timetable.id, name: timetable.sender))
							} label: {
								HStack {
									Text(timetable.sender)
										.foregroundStyle(.primary)
									Spacer()
									Image(systemName: "square.and.arrow.down")
										.foregroundStyle(.secondary)
								}
							}
						}
					}
				}
			}
			.scrollEdgeEffectStyle(.soft, for: .top)
			.appNavigationTitle("Share Timetable", style: .subview)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					}
				}
			}
		}
	}
}
