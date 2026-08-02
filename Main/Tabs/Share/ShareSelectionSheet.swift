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
	case received(id: String, name: String)

	var id: String {
		switch self {
			case let .owner(id): "owner-\(id.uuidString)"
			case let .received(id, _): "received-\(id)"
		}
	}
}

struct ShareSelectionSheet: View {
	@Environment(\.dismiss) private var dismiss
	@Default(.ownerTimetableShareAlias) private var ownerTimetableShareAlias
	@Default(.receivedTimetables) var receivedTimetables
	@State private var showAliasEditor = false
	@State private var aliasService = TimetableShareAliasService.shared
	@Environment(\.statusBadgeManager) private var statusBadgeManager

	let onSelect: (SelectedShareItem) -> Void

	var body: some View {
		NavigationStack {
			List {
				if let ownerID = UUID(uuidString: Defaults[.ownerTimetableID]) {
					Section("Your Timetable") {
						if let url = TimetableShareURL.ownerURL(id: ownerID, alias: ownerTimetableShareAlias) {
							Button {
								dismiss()
								onSelect(.owner(id: ownerID))
							} label: {
								VStack {
									HStack {
										VStack(alignment: .leading) {
											Text(verbatim: Defaults[.accountProfile].map { "\($0.displayName)'s Timetable" } ?? "Your Timetable")

											Text(url.path.trimmingPrefix("/share"))
												.font(.callout)
												.foregroundStyle(.secondary)
										}
										.foregroundStyle(.white)

										Spacer()

										Image(systemName: "person.crop.circle")
											.foregroundStyle(.accent)
									}
								}
							}
						}

						Button("Customize Link", systemImage: "link.badge.plus") {
							showAliasEditor = true
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
			.task {
				await aliasService.fetchCurrentAlias()
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
			case let .received(id, _): TimetableShareURL.url(locator: id)
		}
	}
}
