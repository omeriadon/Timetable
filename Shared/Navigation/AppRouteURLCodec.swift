import Foundation

enum AppRouteURLCodec {
	static let scheme = "timetable"

	private static let host = "route"
	private static let version = "1"

	static func url(for route: AppRoute) -> URL? {
		guard let data = try? JSONEncoder().encode(route) else {
			return nil
		}

		var components = URLComponents()
		components.scheme = scheme
		components.host = host
		components.queryItems = [
			URLQueryItem(name: "version", value: version),
			URLQueryItem(name: "payload", value: data.base64EncodedString()),
		]
		return components.url
	}

	static func route(from url: URL) -> AppRoute? {
		guard url.scheme?.lowercased() == scheme else {
			return nil
		}

		if url.host?.lowercased() == host {
			return decodeCanonicalRoute(from: url)
		}

		return decodeLegacyTimetableRoute(from: url)
	}

	private static func decodeCanonicalRoute(from url: URL) -> AppRoute? {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
		      components.queryItems?.first(where: { $0.name == "version" })?.value == version,
		      let payload = components.queryItems?.first(where: { $0.name == "payload" })?.value,
		      let data = Data(base64Encoded: payload)
		else {
			return nil
		}

		return try? JSONDecoder().decode(AppRoute.self, from: data)
	}

	private static func decodeLegacyTimetableRoute(from url: URL) -> AppRoute? {
		let parts = [url.host]
			.compactMap(\.self)
			+ url.pathComponents.dropFirst().filter { $0 != "/" }

		guard let first = parts.first else {
			return .timetable(.root)
		}

		if first == "timetable" || first == "owner", parts.count == 1 {
			return .timetable(.root)
		}

		if first == "owner", parts.count >= 3, parts[1] == "subject" {
			return .timetable(
				.subject(
					timetableID: nil,
					subjectID: String(parts[2]),
					slot: slot(from: url)
				)
			)
		}

		return nil
	}

	private static func slot(from url: URL) -> Slot? {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
		      let queryItems = components.queryItems,
		      let day = queryItems.first(where: { $0.name == "day" })?.value.flatMap(Int.init),
		      let session = queryItems.first(where: { $0.name == "session" })?.value.flatMap(Int.init)
		else {
			return nil
		}
		return Slot(day, session)
	}
}
