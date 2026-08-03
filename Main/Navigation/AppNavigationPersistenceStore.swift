import Foundation

struct AppNavigationPersistenceStore {
	private let defaults: UserDefaults
	private let snapshotKey = "appNavigationSnapshot_v1"

	init(
		defaults: UserDefaults = UserDefaults(suiteName: SharedDefaultsStore.suiteName) ?? .standard
	) {
		self.defaults = defaults
	}

	func load() -> AppNavigationSnapshot? {
		guard let data = defaults.data(forKey: snapshotKey),
		      let snapshot = try? JSONDecoder().decode(AppNavigationSnapshot.self, from: data),
		      snapshot.version == AppNavigationSnapshot.currentVersion
		else {
			return nil
		}
		return snapshot
	}

	func save(_ snapshot: AppNavigationSnapshot) {
		guard let data = try? JSONEncoder().encode(snapshot) else {
			return
		}
		defaults.set(data, forKey: snapshotKey)
	}

	func clear() {
		defaults.removeObject(forKey: snapshotKey)
	}
}
