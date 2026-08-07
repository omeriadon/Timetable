//
//  LocationStatusPermissionRecoveryRow.swift
//  Main
//

import CoreLocation
import SwiftUI
import UIKit

struct LocationStatusPermissionRecoveryRow: View {
	@State private var service = LocationStatusService.shared

	var body: some View {
		if service.authorizationStatus != .authorizedAlways {
			Button("Open Location Settings", systemImage: "location.fill") {
				if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
					UIApplication.shared.open(settingsURL)
				}
			}
		}
	}
}
