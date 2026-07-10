import AppIntents

struct WeeklyScheduleConfigurationIntent: WidgetConfigurationIntent {
	static var title: LocalizedStringResource = "Choose Person"
	static var description = IntentDescription("Choose whose weekly timetable appears in the widget.")

	@Parameter(title: "Person")
	var person: PersonTimetableEntity?

	static var parameterSummary: some ParameterSummary {
		Summary("Show \(\.$person)'s timetable")
	}
}
