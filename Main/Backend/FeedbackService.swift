import Foundation

@MainActor
enum FeedbackService {
	static func submit(category: String, message: String) async throws {
		try Platform.require(Platform.current.allowsSharing)
		try await NetworkManager.shared.send(
			Endpoint("/v1/report/feedback", method: .post),
			body: FeedbackRequest(category: category, message: message)
		)
	}
}
