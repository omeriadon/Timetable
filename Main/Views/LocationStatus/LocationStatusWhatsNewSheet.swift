//
//  LocationStatusWhatsNewSheet.swift
//  Main
//

import CoreLocation
import SwiftUI
import UIKit

struct LocationStatusWhatsNewSheet: View {
	let close: () -> Void

	@State private var service = LocationStatusService.shared

	var body: some View {
		ZStack {
			OnboardingBackground(currentPageID: "location-status")

			VStack(spacing: 32) {
				Image(systemName: "location.circle.fill")
					.font(.system(size: 72))

				VStack(spacing: 12) {
					Text("Status")
						.font(.largeTitle.bold())

					Text("Timetable can record when you arrive on or leave campus. It stores only on-campus or off-campus status and the time it changed.")
						.multilineTextAlignment(.center)
				}

				permissionAction
			}
			.padding(32)
		}
		.foregroundStyle(.primary)
	}

	@ViewBuilder
	private var permissionAction: some View {
		switch service.authorizationStatus {
			case .authorizedAlways:
				Label("Location access enabled", systemImage: "checkmark.circle.fill")
					.font(.title3)
				Button("Continue", systemImage: "arrow.right", role: .confirm) {
					close()
				}
				.buttonStyle(.glassProminent)
			case .denied, .restricted:
				settingsRecovery
			case .authorizedWhenInUse where service.hasRequestedAlwaysAuthorization:
				settingsRecovery
			case .notDetermined, .authorizedWhenInUse:
				VStack(spacing: 16) {
					Button("Enable Status", systemImage: "location.fill", role: .confirm) {
						service.requestAuthorization()
					}
					.buttonStyle(.glassProminent)

					Button(role: .cancel) {
						close()
					}
				}
			@unknown default:
				Button(role: .cancel) {
					close()
				}
		}
	}

	private var settingsRecovery: some View {
		VStack(spacing: 16) {
			Text("Allow Always location access in Settings to use Status.")
				.multilineTextAlignment(.center)
			Button("Open Settings", systemImage: "gear", role: .confirm) {
				if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
					UIApplication.shared.open(settingsURL)
				}
			}
			.buttonStyle(.glassProminent)
			Button(role: .cancel) {
				close()
			}
		}
	}
}
