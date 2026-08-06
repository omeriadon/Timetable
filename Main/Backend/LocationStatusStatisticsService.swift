//
//  LocationStatusStatisticsService.swift
//  Main
//

import Foundation

@MainActor
final class LocationStatusStatisticsService {
	static let shared = LocationStatusStatisticsService(networkManager: .shared)

	private let networkManager: NetworkManager

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func personalArrivalStatistics() async throws -> LocationArrivalStatisticsResponse {
		try await networkManager.send(.v1LocationStatusPersonalStatistics)
	}

	func administrationStatistics() async throws -> AdministrationStatisticsResponse {
		try await networkManager.send(.v1AdministrationLocationStatusStatistics)
	}
}

extension Endpoint {
	static let v1LocationStatusUpdate = Endpoint("/v1/account/status", method: .post)
	static let v1LocationStatusPersonalStatistics = Endpoint("/v1/account/status/statistics")
	static let v1AdministrationLocationStatusStatistics = Endpoint("/v1/administration/statistics")
}
