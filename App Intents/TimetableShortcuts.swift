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
	}

	static var shortcutTileColor: ShortcutTileColor = .blue
}
