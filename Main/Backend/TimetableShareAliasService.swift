import Defaults
import Foundation
import Observation

@MainActor
@Observable
final class TimetableShareAliasService {
	static let shared = TimetableShareAliasService(networkManager: .shared)

	private(set) var currentAlias = Defaults[.ownerTimetableShareAlias]
	private(set) var candidate = ""
	private(set) var validation: TimetableShareAliasValidationError?
	private(set) var availability: TimetableShareAliasAvailabilityResponse?
	private(set) var isLoadingCurrentAlias = false
	private(set) var isSaving = false
	private(set) var errorMessage: String?

	private let networkManager: NetworkManager
	private var availabilityTask: Task<Void, Never>?
	private var generation = 0

	private init(networkManager: NetworkManager) {
		self.networkManager = networkManager
	}

	func fetchCurrentAlias() async {
		guard SessionStore.shared.isAuthenticated else { return }
		isLoadingCurrentAlias = true
		defer { isLoadingCurrentAlias = false }
		do {
			let response: TimetableShareAliasResponse = try await networkManager.send(.v1OwnerShareAlias)
			currentAlias = response.alias ?? ""
			Defaults[.ownerTimetableShareAlias] = currentAlias
		} catch { errorMessage = error.isCancellation ? nil : "Unable to load your custom link." }
	}

	func updateCandidate(_ raw: String) {
		candidate = String(raw.prefix(64)).lowercased()
		generation += 1
		let requestGeneration = generation
		validation = TimetableShareAliasValidator.validate(candidate)
		availability = nil
		availabilityTask?.cancel()
		guard validation == nil else { return }
		availabilityTask = Task { @MainActor [weak self] in
			try? await Task.sleep(for: .milliseconds(300))
			guard !Task.isCancelled, let self else { return }
			do {
				let response: TimetableShareAliasAvailabilityResponse = try await networkManager.send(.v1OwnerShareAliasAvailability(candidate))
				guard requestGeneration == generation, response.normalizedAlias == candidate else { return }
				availability = response
			} catch where error.isCancellation {}
			catch {
				if requestGeneration == generation {
					errorMessage = "Unable to check that link."
				}
			}
		}
	}

	func save() async -> Bool {
		guard validation == nil, availability?.isAvailable == true, !isSaving else { return false }
		guard Platform.current.allowsOwnerMutation else { return false }
		isSaving = true
		defer { isSaving = false }
		do {
			let response: TimetableShareAliasResponse = try await networkManager.send(.v1OwnerShareAlias, body: TimetableShareAliasUpdateRequest(alias: candidate), context: .userInitiated)
			currentAlias = response.alias ?? ""
			Defaults[.ownerTimetableShareAlias] = currentAlias
			return true
		} catch {
			errorMessage = error.isCancellation ? nil : "That link could not be saved."
			return false
		}
	}

	func remove() async -> Bool {
		guard Platform.current.allowsOwnerMutation else { return false }
		do {
			try await networkManager.send(.v1OwnerShareAliasDelete, context: .userInitiated)
			currentAlias = ""
			Defaults[.ownerTimetableShareAlias] = ""
			return true
		} catch {
			errorMessage = "That link could not be removed."
			return false
		}
	}
}

private extension Endpoint {
	static let v1OwnerShareAlias = Endpoint("/v1/timetables/owner/share-alias")
	static let v1OwnerShareAliasDelete = Endpoint("/v1/timetables/owner/share-alias", method: .delete)
	static func v1OwnerShareAliasAvailability(_ alias: String) -> Endpoint {
		Endpoint("/v1/timetables/owner/share-alias/availability", queryItems: [URLQueryItem(name: "alias", value: alias)])
	}
}
