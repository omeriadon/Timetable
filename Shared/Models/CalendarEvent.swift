import Defaults
import Foundation

nonisolated struct CalendarEvent: Codable, Defaults.Serializable, Hashable, Identifiable, Sendable {
	let id: UUID
	let title: String
	let notes: String?
	let symbol: String
	let date: SchoolCalendarDate
	let isGlobal: Bool
}

nonisolated struct CalendarEventsProjection: Codable, Defaults.Serializable, Hashable, Sendable {
	let globalEvents: [CalendarEvent]
	let privateEvents: [CalendarEvent]
	let canManageGlobalEvents: Bool

	static let empty = CalendarEventsProjection(globalEvents: [], privateEvents: [], canManageGlobalEvents: false)

	var allEvents: [CalendarEvent] {
		(globalEvents + privateEvents).sorted { lhs, rhs in
			lhs.date < rhs.date
		}
	}
}

nonisolated struct EventNotificationSchedule: Codable, Defaults.Serializable, Hashable, Sendable {
	let hour: Int
	let minute: Int
	let dayOffset: Int

	var timeLabel: String {
		let formatter = DateFormatter()
		formatter.locale = Locale.autoupdatingCurrent
		formatter.timeStyle = .short
		formatter.dateStyle = .none
		return formatter.string(from: Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now)
	}

	var offsetLabel: String {
		switch dayOffset {
			case 0: "On the day"
			case 1: "1 day before"
			default: "\(dayOffset) days before"
		}
	}
}

extension SchoolCalendarDate: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		if lhs.year != rhs.year {
			return lhs.year < rhs.year
		}
		if lhs.month != rhs.month {
			return lhs.month < rhs.month
		}
		return lhs.day < rhs.day
	}

	init(_ date: Date, calendar: Calendar = SchoolCalendarProjection.perthCalendar) {
		let components = calendar.dateComponents([.year, .month, .day], from: date)
		year = components.year ?? 0
		month = components.month ?? 0
		day = components.day ?? 0
	}

	func startOfDay(calendar: Calendar = SchoolCalendarProjection.perthCalendar) -> Date? {
		calendar.date(from: components)
	}

	var displayLabel: String {
		guard let date = startOfDay() else { return "" }
		return date.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
	}
}
