//
//  LocationStatusService.swift
//  Main
//

#if os(iOS) && !targetEnvironment(macCatalyst)
	import CoreLocation
	import Defaults
	import Foundation
	import Observation

	@MainActor
	@Observable
	final class LocationStatusService: NSObject, CLLocationManagerDelegate {
		static let shared = LocationStatusService(networkManager: .shared)

		private let networkManager: NetworkManager
		private let locationManager = CLLocationManager()
		private var isMonitoring = false
		private var isFlushing = false

		private(set) var authorizationStatus: CLAuthorizationStatus
		private(set) var hasRequestedAlwaysAuthorization = false

		private init(networkManager: NetworkManager) {
			self.networkManager = networkManager
			authorizationStatus = locationManager.authorizationStatus
			super.init()
			locationManager.delegate = self
		}

		func start() async {
			guard Platform.current == .iOS else {
				return
			}

			await flushPendingUpdates()
			startMonitoringIfAuthorized()
		}

		func requestAuthorization() {
			guard Platform.current == .iOS else {
				return
			}

			switch locationManager.authorizationStatus {
				case .notDetermined:
					locationManager.requestWhenInUseAuthorization()
				case .authorizedWhenInUse:
					hasRequestedAlwaysAuthorization = true
					locationManager.requestAlwaysAuthorization()
				case .authorizedAlways:
					startMonitoringIfAuthorized()
				case .denied, .restricted:
					break
				@unknown default:
					break
			}
		}

		func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
			authorizationStatus = manager.authorizationStatus

			switch manager.authorizationStatus {
				case .authorizedWhenInUse:
					hasRequestedAlwaysAuthorization = true
					manager.requestAlwaysAuthorization()
				case .authorizedAlways:
					startMonitoringIfAuthorized()
				case .notDetermined, .denied, .restricted:
					break
				@unknown default:
					break
			}
		}

		func locationManager(_: CLLocationManager, didEnterRegion region: CLRegion) {
			guard region.identifier == Self.schoolRegion.identifier else {
				return
			}

			record(.onCampus)
		}

		func locationManager(_: CLLocationManager, didExitRegion region: CLRegion) {
			guard region.identifier == Self.schoolRegion.identifier else {
				return
			}

			record(.offCampus)
		}

		func locationManager(
			_: CLLocationManager,
			didDetermineState state: CLRegionState,
			for region: CLRegion
		) {
			guard region.identifier == Self.schoolRegion.identifier else {
				return
			}

			switch state {
				case .inside:
					record(.onCampus)
				case .outside:
					record(.offCampus)
				case .unknown:
					break
				@unknown default:
					break
			}
		}

		private func startMonitoringIfAuthorized() {
			guard locationManager.authorizationStatus == .authorizedAlways else {
				return
			}

			if !isMonitoring {
				locationManager.startMonitoring(for: Self.schoolRegion)
				isMonitoring = true
			}

			locationManager.requestState(for: Self.schoolRegion)
		}

		private func record(_ state: LocationStatus) {
			let item = LocationStatusItem(state: state, updatedAt: .now)
			guard Defaults[.locationStatus]?.state != state else {
				return
			}

			Defaults[.locationStatus] = item
			var pendingUpdates = Defaults[.pendingLocationStatusUpdates]
			pendingUpdates.append(item)
			Defaults[.pendingLocationStatusUpdates] = pendingUpdates

			Task {
				await flushPendingUpdates()
			}
		}

		private func flushPendingUpdates() async {
			guard !isFlushing, SessionStore.shared.isAuthenticated else {
				return
			}

			isFlushing = true
			defer {
				isFlushing = false
			}

			while let item = Defaults[.pendingLocationStatusUpdates].first {
				do {
					try await networkManager.send(
						Endpoint("/v1/account/status", method: .post),
						body: LocationStatusUpdateRequest(
							state: item.state,
							updatedAt: item.updatedAt
						)
					)
					var pendingUpdates = Defaults[.pendingLocationStatusUpdates]
					pendingUpdates.removeFirst()
					Defaults[.pendingLocationStatusUpdates] = pendingUpdates
				} catch {
					PrintError("Location status upload failed", category: .network, error: error)
					return
				}
			}
		}

		private static let schoolRegion = CLCircularRegion(
			center: CLLocationCoordinate2D(
				latitude: -31.944462605584388,
				longitude: 115.8380028573902
			),
			radius: 225,
			identifier: "school-campus"
		)
	}
#endif // os(iOS) && !targetEnvironment(macCatalyst)
