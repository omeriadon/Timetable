//
//  LocationStatusService.swift
//  Main
//

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
		guard Platform.current == .iOS, Defaults[.locationStatusEnabled] else {
			return
		}

		await flushPendingUpdates()
		await refreshCurrentStatus()
		startMonitoringIfAuthorized()
	}

	func requestAuthorization() {
		guard Platform.current == .iOS, Defaults[.locationStatusEnabled] else {
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

	func setEnabled(_ isEnabled: Bool) {
		Defaults[.locationStatusEnabled] = isEnabled
		if isEnabled {
			requestAuthorization()
			Task {
				await start()
			}
		} else {
			stopMonitoring()
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
		handleEntry(for: region.identifier)
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
		guard Self.region(for: region.identifier) != nil else {
			return
		}

		switch state {
			case .inside:
				handleEntry(for: region.identifier)
			case .outside:
				if region.identifier == Self.schoolRegion.identifier {
					record(.offCampus)
				}
			case .unknown:
				break
			@unknown default:
				break
		}
	}

	private func handleEntry(for identifier: String) {
		switch identifier {
			case Self.schoolRegion.identifier:
				record(.onCampus)
			case Self.withinFiveMinutesRegion.identifier:
				guard Defaults[.locationStatus]?.state == .offCampus
					|| Defaults[.locationStatus]?.state == .withinTenMinutes
				else {
					return
				}
				record(.withinFiveMinutes)
			case Self.withinTenMinutesRegion.identifier:
				guard Defaults[.locationStatus]?.state == .offCampus else {
					return
				}
				record(.withinTenMinutes)
			default:
				return
		}
	}

	private func startMonitoringIfAuthorized() {
		guard Defaults[.locationStatusEnabled], locationManager.authorizationStatus == .authorizedAlways else {
			return
		}

		if !isMonitoring {
			locationManager.startMonitoring(for: Self.schoolRegion)
			locationManager.startMonitoring(for: Self.withinFiveMinutesRegion)
			locationManager.startMonitoring(for: Self.withinTenMinutesRegion)
			isMonitoring = true
		}

		locationManager.requestState(for: Self.schoolRegion)
		locationManager.requestState(for: Self.withinFiveMinutesRegion)
		locationManager.requestState(for: Self.withinTenMinutesRegion)
	}

	private func stopMonitoring() {
		locationManager.stopMonitoring(for: Self.schoolRegion)
		locationManager.stopMonitoring(for: Self.withinFiveMinutesRegion)
		locationManager.stopMonitoring(for: Self.withinTenMinutesRegion)
		isMonitoring = false
	}

	private func record(_ state: LocationStatus) {
		guard Defaults[.locationStatusEnabled] else {
			return
		}
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

	private func refreshCurrentStatus() async {
		guard SessionStore.shared.isAuthenticated else {
			return
		}

		do {
			let response: LocationStatusCurrentResponse = try await networkManager.send(
				Endpoint("/v1/account/status")
			)
			if let item = response.item {
				Defaults[.locationStatus] = item
			}
		} catch {
			PrintError("Location status refresh failed", category: .network, error: error)
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

	private static let withinFiveMinutesRegion = CLCircularRegion(
		center: schoolRegion.center,
		radius: 1500,
		identifier: "school-campus-within-5-minutes"
	)

	private static let withinTenMinutesRegion = CLCircularRegion(
		center: schoolRegion.center,
		radius: 3500,
		identifier: "school-campus-within-10-minutes"
	)

	private static func region(for identifier: String) -> CLCircularRegion? {
		switch identifier {
			case schoolRegion.identifier:
				schoolRegion
			case withinFiveMinutesRegion.identifier:
				withinFiveMinutesRegion
			case withinTenMinutesRegion.identifier:
				withinTenMinutesRegion
			default:
				nil
		}
	}
}
