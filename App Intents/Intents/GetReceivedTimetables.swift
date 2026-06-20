//
//  GetReceivedTimetables.swift
//  Timetable
//
//  Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import Defaults

struct GetReceivedTimetablesIntent: AppIntent {

	static var title: LocalizedStringResource = "Get Received Timetables"


	static var description = IntentDescription("Fetches all the timetables you have received from friends.")

	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

	static var supportedModes: IntentModes = .background

//	static var parameterSummary: SummaryContent




	static var isDiscoverable: Bool = true


	@MainActor
	func perform() async throws -> some ReturnsValue<[TimetableEntity]> {
		return .result(value: Defaults[.receivedTimetables].toTimetableEntities())
	}
}
