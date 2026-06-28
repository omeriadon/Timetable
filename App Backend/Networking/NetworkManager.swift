//
//   NetworkManager.swift
//   Shared
//
//   Created by Adon Omeri on 28/6/2026.
//

import Foundation
import Network
import Observation

enum HTTPMethod: String {
	case delete = "DELETE"
	case get = "GET"
	case patch = "PATCH"
	case post = "POST"
	case put = "PUT"
}

struct Endpoint {
	let path: String
	let method: HTTPMethod
	let queryItems: [URLQueryItem]
	let requiresAuthentication: Bool

	init(
		_ path: String,
		method: HTTPMethod = .get,
		queryItems: [URLQueryItem] = [],
		requiresAuthentication: Bool = true
	) {
		self.path = path
		self.method = method
		self.queryItems = queryItems
		self.requiresAuthentication = requiresAuthentication
	}
}

enum ServerErrorCode: String, Codable {
	case accountNotFound
	case conflict
	case emailAlreadyExists
	case internalServerError
	case invalidAppleIdentityToken
	case invalidCredentials
	case invalidRequest
	case invalidTimetable
	case liveActivityDisabled
	case notFound
	case offline
	case passGenerationFailed
	case passRevoked
	case rateLimited
	case sessionExpired
	case timetableConflict
	case unauthorized
	case unknown

	init(from decoder: any Decoder) throws {
		let value = try decoder.singleValueContainer().decode(String.self)
		self = Self(rawValue: value) ?? .unknown
	}
}

struct ServerErrorResponse: Codable {
	let code: ServerErrorCode
	let message: String
	let field: String?
	let requestID: String
}

struct NetworkAlert: Identifiable {
	let id = UUID()
	let title: String
	let message: String
}

enum NetworkError: Error, LocalizedError {
	case cancelled
	case invalidConfiguration
	case invalidResponse
	case offline
	case server(statusCode: Int, response: ServerErrorResponse)
	case timedOut
	case transport(String)

	var errorDescription: String? {
		switch self {
			case .cancelled:
				"The request was cancelled."
			case .invalidConfiguration:
				"The timetable server URL is not configured."
			case .invalidResponse:
				"The server returned an invalid response."
			case .offline:
				"Connect to the internet and try again."
			case let .server(_, response):
				response.message
			case .timedOut:
				"The server took too long to respond."
			case let .transport(message):
				message
		}
	}
}

@MainActor
@Observable
final class NetworkManager {
	static let shared = NetworkManager()

	private(set) var isOnline = true
	var presentedAlert: NetworkAlert?

	private let baseURL: URL?
	private let decoder: JSONDecoder
	private let encoder: JSONEncoder
	private let monitor: NWPathMonitor
	private let monitorQueue = DispatchQueue(label: "com.omeriadon.timetable.network-monitor")
	private let session: URLSession
	private var isMonitoring = false
	private var accessTokenProvider: (@MainActor @Sendable () -> String?)?
	private var refreshHandler: (@MainActor @Sendable () async throws -> Void)?
	private var refreshTask: Task<Void, any Error>?

	init(
		baseURL: URL? = NetworkManager.configuredBaseURL,
		session: URLSession? = nil,
		monitor: NWPathMonitor = NWPathMonitor()
	) {
		self.baseURL = baseURL
		self.session = session ?? Self.makeSession()
		self.monitor = monitor

		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		self.decoder = decoder

		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		self.encoder = encoder
	}

	// MARK: - State

	func configureAuthentication(
		accessToken: @escaping @MainActor @Sendable () -> String?,
		refresh: @escaping @MainActor @Sendable () async throws -> Void
	) {
		accessTokenProvider = accessToken
		refreshHandler = refresh
	}

	func clearAuthentication() {
		accessTokenProvider = nil
		refreshHandler = nil
	}

	// MARK: - Reachability

	func startMonitoring() {
		guard !isMonitoring else { return }
		isMonitoring = true
		monitor.pathUpdateHandler = { [weak self] path in
			Task { @MainActor [weak self] in
				self?.isOnline = path.status != .unsatisfied
			}
		}
		monitor.start(queue: monitorQueue)
	}

	func requireOnline() throws {
		guard isOnline else {
			let error = NetworkError.offline
			present(error)
			throw error
		}
	}

	// MARK: - Authentication

	private func refreshAuthentication() async throws -> Bool {
		guard let refreshHandler else { return false }
		if let refreshTask {
			try await refreshTask.value
			return true
		}

		let task = Task { @MainActor in
			try await refreshHandler()
		}
		refreshTask = task
		defer { refreshTask = nil }
		try await task.value
		return true
	}

	// MARK: - Request Construction

	private nonisolated static var configuredBaseURL: URL? {
		let processValue = ProcessInfo.processInfo.environment["TIMETABLE_SERVER_URL"]
		let bundleValue = Bundle.main.object(forInfoDictionaryKey: "TIMETABLE_SERVER_URL") as? String
		return (processValue ?? bundleValue).flatMap(URL.init(string:))
	}

	private nonisolated static func makeSession() -> URLSession {
		let configuration = URLSessionConfiguration.default
		configuration.timeoutIntervalForRequest = 30
		configuration.timeoutIntervalForResource = 300
		configuration.waitsForConnectivity = true
		configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
		return URLSession(configuration: configuration)
	}

	private func makeRequest(for endpoint: Endpoint, body: Data?) throws -> URLRequest {
		guard let baseURL else {
			throw NetworkError.invalidConfiguration
		}

		let normalizedPath = endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
		let url = baseURL.appending(path: normalizedPath)
		guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
			throw NetworkError.invalidConfiguration
		}
		components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems
		guard let requestURL = components.url else {
			throw NetworkError.invalidConfiguration
		}

		var request = URLRequest(url: requestURL)
		request.httpMethod = endpoint.method.rawValue
		request.httpBody = body
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		if body != nil {
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		}
		if endpoint.requiresAuthentication, let accessToken = accessTokenProvider?() {
			request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
		}
		return request
	}

	// MARK: - Request Execution

	private func execute(_ endpoint: Endpoint, body: Data?, mayRefresh: Bool = true) async throws -> Data {
		try requireOnline()
		let clock = ContinuousClock()
		let start = clock.now

		do {
			let request = try makeRequest(for: endpoint, body: body)
			let (data, response) = try await session.data(for: request)
			guard let response = response as? HTTPURLResponse else {
				throw NetworkError.invalidResponse
			}

			if response.statusCode == 401, endpoint.requiresAuthentication, mayRefresh, try await refreshAuthentication() {
				return try await execute(endpoint, body: body, mayRefresh: false)
			}

			try validate(response: response, data: data)
			Print(
				"\(endpoint.method.rawValue) \(endpoint.path) completed with status \(response.statusCode)",
				category: .network,
				duration: start.duration(to: clock.now)
			)
			return data
		} catch let error as NetworkError {
			PrintError("Request failed for \(endpoint.path)", category: .network, error: error)
			if case .cancelled = error {
				throw error
			}
			present(error)
			throw error
		} catch is CancellationError {
			throw NetworkError.cancelled
		} catch let error as URLError {
			let networkError = map(error)
			if case .cancelled = networkError {
				throw networkError
			}
			PrintError("Transport failed for \(endpoint.path)", category: .network, error: error)
			present(networkError)
			throw networkError
		} catch {
			let networkError = NetworkError.transport(error.localizedDescription)
			PrintError("Transport failed for \(endpoint.path)", category: .network, error: error)
			present(networkError)
			throw networkError
		}
	}

	private func map(_ error: URLError) -> NetworkError {
		switch error.code {
			case .cancelled:
				.cancelled
			case .networkConnectionLost, .notConnectedToInternet:
				.offline
			case .timedOut:
				.timedOut
			default:
				.transport(error.localizedDescription)
		}
	}

	// MARK: - Response Validation

	private func validate(response: HTTPURLResponse, data: Data) throws {
		guard (200 ..< 300).contains(response.statusCode) else {
			let serverError = try? decoder.decode(ServerErrorResponse.self, from: data)
			let fallback = ServerErrorResponse(
				code: response.statusCode == 401 ? .sessionExpired : .unknown,
				message: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
				field: nil,
				requestID: response.value(forHTTPHeaderField: "X-Request-ID") ?? "unknown"
			)
			throw NetworkError.server(statusCode: response.statusCode, response: serverError ?? fallback)
		}
	}

	// MARK: - Decoding

	func send<Response: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> Response {
		try await decode(execute(endpoint, body: nil))
	}

	func send<Response: Decodable & Sendable>(
		_ endpoint: Endpoint,
		body: some Encodable & Sendable
	) async throws -> Response {
		try await decode(execute(endpoint, body: encoder.encode(body)))
	}

	func send(_ endpoint: Endpoint) async throws {
		_ = try await execute(endpoint, body: nil)
	}

	func send(_ endpoint: Endpoint, body: some Encodable & Sendable) async throws {
		_ = try await execute(endpoint, body: encoder.encode(body))
	}

	private func decode<Response: Decodable & Sendable>(_ data: Data) throws -> Response {
		do {
			return try decoder.decode(Response.self, from: data)
		} catch {
			throw NetworkError.invalidResponse
		}
	}

	// MARK: - Uploads

	func upload<Response: Decodable & Sendable>(
		_ endpoint: Endpoint,
		body: some Encodable & Sendable
	) async throws -> Response {
		try await send(endpoint, body: body)
	}

	// MARK: - Downloads

	func download(_ endpoint: Endpoint) async throws -> Data {
		try await execute(endpoint, body: nil)
	}

	// MARK: - Error Presentation

	func present(_ error: any Error) {
		let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
		presentedAlert = NetworkAlert(title: "Network Error", message: message)
	}
}
