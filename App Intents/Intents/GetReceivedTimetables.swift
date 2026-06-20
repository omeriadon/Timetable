//
//  GetReceivedTimetables.swift
//  Timetable
//
//  Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import Defaults
import SwiftUI

struct GetReceivedTimetablesIntent: AppIntent {
	static var title: LocalizedStringResource = "Get Received Timetables"

	static var description = IntentDescription("Fetches all the timetables you have received from friends.")

	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

	static var supportedModes: IntentModes = .background

	static var isDiscoverable: Bool = true

	@MainActor
	func perform() async -> some ReturnsValue<[TimetableEntity]> & ShowsSnippetView {
		let saved = Defaults[.receivedTimetables]

		let entities = saved.map { $0.toTimetableEntity() }

		if entities.isEmpty {
			return .result(
				value: []
			)
		}

		return .result(
			value: entities,
			view: GetReceivedTimetablesIntentView(entities: entities)
		)
	}
}

struct GetReceivedTimetablesIntentView: View {
	let entities: [TimetableEntity]

	var body: some View {
		VStack(spacing: 10) {
			ForEach(Array(entities).enumerated(), id: \.element.id) { index, entity in
				VStack {
					HStack {
						Text(entity.displayRepresentation.title)

						Spacer()

						if entity.sharedInfo != nil {
							Image(systemName: "person.2.fill")
								.foregroundColor(.accentColor)
								.imageScale(.large)
						}
					}
					.padding(.vertical, 12)

					if index < entities.count - 1 {
						Divider()
					}
				}
				.padding(.horizontal)
			}
		}
		.padding([.bottom, .horizontal])
	}
}
