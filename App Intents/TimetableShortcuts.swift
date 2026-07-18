import AppIntents

struct TimetableShortcuts: AppShortcutsProvider {
	static var appShortcuts: [AppShortcut] {
		AppShortcut(
			intent: GetCurrentSubjectIntent(),
			phrases: ["What's my current subject in \(.applicationName)?"],
			shortTitle: "Current Subject",
			systemImageName: "clock"
		)
		AppShortcut(
			intent: GetNextSubjectIntent(),
			phrases: ["What's my next subject in \(.applicationName)?"],
			shortTitle: "Next Subject",
			systemImageName: "arrow.right.circle"
		)
		AppShortcut(
			intent: GetNextBreakIntent(),
			phrases: ["When is my next break in \(.applicationName)?"],
			shortTitle: "Next Break",
			systemImageName: "cup.and.saucer"
		)
		AppShortcut(
			intent: GetSubjectsForDayIntent(),
			phrases: ["What subjects do I have in \(.applicationName)?"],
			shortTitle: "Subjects for Day",
			systemImageName: "calendar"
		)
		AppShortcut(intent: GetSchoolDaySummaryIntent(), phrases: ["Summarize today's timetable in \(.applicationName)", "Show my school day summary in \(.applicationName)"], shortTitle: "School Day Summary", systemImageName: "list.bullet.clipboard")
		AppShortcut(intent: FindNextSubjectOccurrenceIntent(), phrases: ["Find my next subject in \(.applicationName)"], shortTitle: "Find Subject", systemImageName: "magnifyingglass")
		AppShortcut(intent: GetFreePeriodsIntent(), phrases: ["Show my free periods in \(.applicationName)"], shortTitle: "Free Periods", systemImageName: "studentdesk")
		AppShortcut(intent: CompareTimetablesIntent(), phrases: ["Compare timetables in \(.applicationName)"], shortTitle: "Compare Timetables", systemImageName: "person.2")
		AppShortcut(intent: GetTimeUntilNextSubjectIntent(), phrases: ["How long until my next subject in \(.applicationName)?"], shortTitle: "Time Until Next", systemImageName: "timer")
		AppShortcut(intent: OpenTimetableDestinationIntent(), phrases: ["Open my timetable in \(.applicationName)"], shortTitle: "Open Timetable", systemImageName: "arrow.up.forward.app")
	}

	static var shortcutTileColor: ShortcutTileColor = .blue
}
