import Defaults
import Foundation

nonisolated enum CalendarEventArchivePolicy: Int, CaseIterable, Codable, Defaults.Serializable, Hashable, Sendable {
	case oneWeek = 7
	case thirtyDays = 30
	case oneYear = 365
	case never = 0

	var title: String {
		switch self {
			case .oneWeek: "1 week after they pass"
			case .thirtyDays: "30 days after they pass"
			case .oneYear: "1 year after they pass"
			case .never: "Never"
		}
	}
}

nonisolated struct CalendarEvent: Codable, Defaults.Serializable, Hashable, Identifiable, Sendable {
	let id: UUID
	let title: String
	let notes: String?
	let symbol: String
	let date: SchoolCalendarDate
	let isGlobal: Bool
	let tagIDs: [UUID]
	let showsWeather: Bool
	let weather: SchoolWeather?
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
		case showsWeather
		case weather
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
		showsWeather = isGlobal && (try container.decodeIfPresent(Bool.self, forKey: .showsWeather) ?? false)
		weather = showsWeather ? try container.decodeIfPresent(SchoolWeather.self, forKey: .weather) : nil
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
