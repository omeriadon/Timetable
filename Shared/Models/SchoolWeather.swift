import Defaults
import Foundation

nonisolated struct SchoolWeather: Codable, Defaults.Serializable, Equatable, Hashable, Sendable {
	let temperatureCelsius: Double
	let conditionCode: String
	let uvIndex: Int
	let precipitationChance: Double
	let observedAt: Date
	let fetchedAt: Date
	let isStale: Bool
}
