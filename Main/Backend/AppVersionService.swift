import Foundation

enum AppVersionService {
	static func check() async throws -> AppVersionCheckResponse {
		let build = Int(Bundle.main.buildNumber) ?? 0
		return try await NetworkManager.shared.send(
			Endpoint(
				"/v1/app-version",
				queryItems: [
					URLQueryItem(name: "platform", value: Platform.current.rawValue),
					URLQueryItem(name: "version", value: Bundle.main.appVersion),
					URLQueryItem(name: "build", value: String(build)),
				],
				requiresAuthentication: false
			)
		)
	}
}
