//
//   ShareSelectionSheet.swift
//   Main
//
//   Created by Adon Omeri on 02/07/2026.
//

import Defaults
import SwiftUI

#if os(iOS)
	import UIKit
#endif

#if os(macOS)
	import AppKit
#endif

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
	@State private var showAliasEditor = false
	@Environment(\.statusBadgeManager) private var statusBadgeManager

	let onSelect: (SelectedShareItem) -> Void

	var body: some View {
		NavigationStack {
			List {
				if ownerIsSearchable, let ownerID = UUID(uuidString: Defaults[.ownerTimetableID]) {
					Section("Your Timetable") {
						if let url = SelectedShareItem.owner(id: ownerID).shareURL {
							Button {
								dismiss()
								onSelect(.owner(id: ownerID))
							} label: {
								VStack {
									HStack {
										VStack {
											Text(verbatim: Defaults[.accountProfile].map { "\($0.displayName)'s Timetable" } ?? "Your Timetable")

											Text(url.path.trimmingPrefix("/share"))
												.font(.caption)
										}
										.foregroundStyle(.white)

										Spacer()
										Image(systemName: "person.crop.circle")
											.foregroundStyle(.accent)
									}
								}
							}

							Button {
								copy(url)
							} label: {
								HStack {
									Text(url.path.trimmingPrefix("/share"))
										.font(.body.monospaced())
										.foregroundStyle(.white)
									Spacer()
									Image(systemName: "doc.on.doc")
										.foregroundStyle(.accent)
								}
							}
							.accessibilityLabel("Copy timetable link")
						}

						Button("Customize Link", systemImage: "link.badge.plus") {
							showAliasEditor = true
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
										.foregroundStyle(.white)
									Spacer()
									Image(systemName: "calendar")
										.foregroundStyle(.accent)
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
										.foregroundStyle(.white)
									Spacer()
									Image(systemName: "square.and.arrow.down")
										.foregroundStyle(.accent)
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
			.sheet(isPresented: $showAliasEditor) {
				TimetableShareAliasSheet()
			}
		}
	}

	private func copy(_ url: URL) {
		#if os(iOS)
			UIPasteboard.general.url = url
		#elseif os(macOS)
			NSPasteboard.general.clearContents()
			NSPasteboard.general.setString(url.absoluteString, forType: .string)
		#endif
		statusBadgeManager.addBadge(id: UUID(), title: "Link copied", priority: 3, view: .success)
	}
}

extension SelectedShareItem {
	var shareURL: URL? {
		switch self {
			case let .owner(id): TimetableShareURL.ownerURL(id: id)
			case let .authored(id, _): TimetableShareURL.url(locator: id.uuidString)
			case let .received(id, _): TimetableShareURL.url(locator: id)
		}
	}
}
