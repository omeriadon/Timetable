import Foundation

nonisolated enum FutureEventRange: String, Codable, CaseIterable, Hashable, Identifiable {
	case oneWeek
	case twoWeeks
	case oneMonth
	case twoMonths
	case threeMonths
	case endOfYear

	var id: Self {
		self
	}

	var title: String {
		switch self {
			case .oneWeek:
				"1 Week"
			case .twoWeeks:
				"2 Weeks"
			case .oneMonth:
				"1 Month"
			case .twoMonths:
				"2 Months"
			case .threeMonths:
				"3 Months"
			case .endOfYear:
				"Until End of Year"
		}
	}

	func endDate(from date: Date, calendar: Calendar) -> Date {
		switch self {
			case .oneWeek:
				calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
			case .twoWeeks:
				calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
			case .oneMonth:
				calendar.date(byAdding: .month, value: 1, to: date) ?? date
			case .twoMonths:
				calendar.date(byAdding: .month, value: 2, to: date) ?? date
			case .threeMonths:
				calendar.date(byAdding: .month, value: 3, to: date) ?? date
			case .endOfYear:
				let year = calendar.component(.year, from: date)
				return calendar.date(from: DateComponents(
					year: year,
					month: 12,
					day: 31
				)) ?? date
		}
	}
}
