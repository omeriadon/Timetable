import Foundation

nonisolated struct LiveActivityDebugStateResponse: Codable, Sendable {
	let isActive: Bool
	let canUpdate: Bool
}

nonisolated struct LiveActivityDebugRequest: Codable, Sendable {
	let installationID: String
}

nonisolated struct LiveActivityDebugUpdateRequest: Codable, Sendable {
	let installationID: String
	let transition: String
}
