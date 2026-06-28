//
//   Spotlight.swift
//   App Intents
//
//   Created by Adon Omeri on 20/6/2026.
//

import AppIntents
import CoreSpotlight
import Defaults

func indexEntities() async {
	let timetableIndex = CSSearchableIndex(name: "Timetables")
	let subjectIndex = CSSearchableIndex(name: "Subjects")

	var timetables = Defaults[.receivedTimetables].toTimetableEntities()
	timetables.append(Defaults[.timetable].toTimetableEntity())

	let subjects: [SubjectEntity] = timetables.flatMap(\.subjects)

	try? await timetableIndex.indexAppEntities(timetables)
	try? await subjectIndex.indexAppEntities(subjects)
}
