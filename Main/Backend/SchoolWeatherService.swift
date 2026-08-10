import Defaults
import Foundation

@MainActor
final class SchoolWeatherService {
	static let shared = SchoolWeatherService(networkManager: .shared)

	private let networkManager: NetworkManager

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func refresh() async throws {
		let weather: SchoolWeather = try await networkManager.send(.v1SchoolWeather)
		Defaults[.schoolWeather] = weather
	}
}

private extension Endpoint {
	static let v1SchoolWeather = Endpoint("/v1/weather")
}
