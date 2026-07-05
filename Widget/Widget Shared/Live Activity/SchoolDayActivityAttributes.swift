
import ActivityKit
import Foundation

nonisolated struct SchoolDayActivityAttributes: ActivityAttributes {
	let activityKey: String
	let schoolDate: String

	nonisolated enum Phase: String, Codable, Hashable {
		case beforeSchool
		case lesson
		case freePeriod
		case recess
		case lunch
		case finished
	}

	nonisolated struct ContentState: Codable, Hashable {
		let phase: Phase
		let title: String
		let symbol: String
		let color: RGBAColor
		let nextText: String?
		let startDate: Date?
		let endDate: Date?
	}
}
