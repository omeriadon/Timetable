import Defaults
import Foundation

nonisolated struct CalendarEvent: Codable, Defaults.Serializable, Hashable, Identifiable, Sendable {
	let id: UUID
	let title: String
	let notes: String?
	let symbol: String
	let date: SchoolCalendarDate
	let isGlobal: Bool
	let tagIDs: [UUID]
	let revision: Int
	let updatedAt: Date?

	private enum CodingKeys: String, CodingKey {
		case id
		case title
		case notes
		case symbol
		case date
		case isGlobal
		case tagIDs
		case revision
		case updatedAt
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		title = try container.decode(String.self, forKey: .title)
		notes = try container.decodeIfPresent(String.self, forKey: .notes)
		symbol = try container.decode(String.self, forKey: .symbol)
		date = try container.decode(SchoolCalendarDate.self, forKey: .date)
		isGlobal = try container.decode(Bool.self, forKey: .isGlobal)
		tagIDs = try container.decodeIfPresent([UUID].self, forKey: .tagIDs) ?? []
		revision = try container.decodeIfPresent(Int.self, forKey: .revision) ?? 0
		updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
	}
}

nonisolated struct CalendarEventsProjection: Codable, Defaults.Serializable, Hashable, Sendable {
	let globalEvents: [CalendarEvent]
	let privateEvents: [CalendarEvent]
	let canManageGlobalEvents: Bool

	static let empty = CalendarEventsProjection(globalEvents: [], privateEvents: [], canManageGlobalEvents: false)

	nonisolated var allEvents: [CalendarEvent] {
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
	nonisolated static func < (lhs: Self, rhs: Self) -> Bool {
		if lhs.year != rhs.year {
			return lhs.year < rhs.year
		}
		if lhs.month != rhs.month {
			return lhs.month < rhs.month
		}
		return lhs.day < rhs.day
	}

	nonisolated init(_ date: Date, calendar: Calendar = SchoolCalendarProjection.perthCalendar) {
		let components = calendar.dateComponents([.year, .month, .day], from: date)
		year = components.year ?? 0
		month = components.month ?? 0
		day = components.day ?? 0
	}

	nonisolated func startOfDay(calendar: Calendar = SchoolCalendarProjection.perthCalendar) -> Date? {
		calendar.date(from: components)
	}

	nonisolated var displayLabel: String {
		guard let date = startOfDay() else { return "" }
		return date.formatted(.dateTime.weekday(.wide).day().month(.wide))
	}
}
