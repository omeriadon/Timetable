enum AppRoutePresentationPolicy: Equatable {
	case detail
	case inspector

	init(route: AppRoute) {
		switch route {
			case .friends(.addFriend), .friends(.requests), .friends(.friend(id: _)):
				self = .inspector
			case .settings(.root):
				self = .detail
			case .settings:
				self = .inspector
			case .administration(.root):
				self = .detail
			case .administration:
				self = .inspector
			case .timetable(.subject(timetableID: _, subjectID: _, slot: _)),
			     .timetable(.calendarEvent(id: _)):
				self = .inspector
			default:
				self = .detail
		}
	}
}
