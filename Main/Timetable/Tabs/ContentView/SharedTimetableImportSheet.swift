//
//  SharedTimetableImportSheet.swift
//  Timetable
//
//  Created by Adon Omeri on 11/6/2026.
//

import SwiftUI

struct SharedTimetableImportSheet: View {
	let timetable: ReceivedTimetable
	let onCancel: () -> Void
	let onImport: () -> Void

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 16) {
					VStack(alignment: .leading, spacing: 8) {
						Text(timetable.sender)
							.font(.headline)
						Text("\(timetable.classes.count) classes shared")
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					.frame(maxWidth: .infinity, alignment: .leading)

					TimetableGridPreview(
						classes: timetable.classes,
						showsTitle: false
					)
					.clipShape(RoundedRectangle(cornerRadius: 16))
				}
				.padding()
			}
			.navigationTitle("Import Timetable")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel", action: onCancel)
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Import", action: onImport)
						.buttonStyle(.glassProminent)
				}
			}
		}
		.monospaced()
	}
}

#Preview {
	SharedTimetableImportSheet(
		timetable: ReceivedTimetable(
			sender: "Monkey",
			classes: defaultTimetable,
			receivedAt: Date()
		),
		onCancel: {

		},
		onImport: {

		}
	)
}
