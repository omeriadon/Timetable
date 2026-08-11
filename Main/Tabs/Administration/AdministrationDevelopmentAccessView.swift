import SwiftUI

struct AdministrationDevelopmentAccessView: View {
	@State private var service = AdministrationService.shared
	@State private var developmentAccessOnly: Bool?
	@State private var pendingDevelopmentAccessOnly: Bool?
	@State private var isUpdating = false
	@State private var loadError: String?
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List {
			Section {
				if let developmentAccessOnly {
					Toggle(
						"Restrict Server to System Administrators",
						isOn: Binding(
							get: { developmentAccessOnly },
							set: { pendingDevelopmentAccessOnly = $0 }
						)
					)
					.disabled(isUpdating)
				} else if let loadError {
					VStack(alignment: .leading, spacing: 12) {
						Label("Unable to load server access", systemImage: "exclamationmark.triangle")
							.foregroundStyle(.orange)

						Text(loadError)
							.font(.footnote)
							.foregroundStyle(.secondary)

						Button("Retry", systemImage: "arrow.clockwise") {
							Task {
								await load()
							}
						}
					}
				} else {
					ProgressView("Loading Server Access")
				}
			} header: {
				Text("Development Access")
			} footer: {
				Text("When enabled, only the two system administrator accounts can use the server. Existing sessions remain intact but receive an access error.")
			}
			.glurListRowBackground()
		}
		.scrollEdgeEffect()
		.appPaperBackground()
		.appNavigationTitle("Debug Testing", accent: true)
		.task {
			await load()
		}
		.refreshable {
			await load()
		}
		.confirmationDialog(
			pendingDevelopmentAccessOnly == true ? "Restrict Server to System Administrators?" : "Restore Normal Server Access?",
			isPresented: Binding(
				get: { pendingDevelopmentAccessOnly != nil },
				set: { isPresented in
					if !isPresented {
						pendingDevelopmentAccessOnly = nil
					}
				}
			),
			titleVisibility: .visible
		) {
			if let pendingDevelopmentAccessOnly {
				Button(
					pendingDevelopmentAccessOnly ? "Restrict to System Administrators" : "Restore Normal Access",
					systemImage: pendingDevelopmentAccessOnly ? "lock.fill" : "lock.open",
					role: .confirm
				) {
					update(developmentAccessOnly: pendingDevelopmentAccessOnly)
				}
			}
		} message: {
			Text(
				pendingDevelopmentAccessOnly == true
					? "All non-system-administrator accounts will receive an access error until normal access is restored."
					: "All accounts will be able to use the server again."
			)
		}
	}

	private func load() async {
		isUpdating = true
		loadError = nil
		defer {
			isUpdating = false
		}

		Print("Loading server access mode", category: .network)

		do {
			let response = try await service.serverAccessMode()
			developmentAccessOnly = response.developmentAccessOnly
			Print("Loaded server access mode: development_access_only=\(response.developmentAccessOnly)", category: .network)
		} catch {
			loadError = error.localizedDescription
			PrintError("Unable to load server access mode", category: .network, error: error)
			badges.present(error: error, title: "Unable to load server access")
		}
	}

	private func update(developmentAccessOnly: Bool) {
		isUpdating = true
		Task {
			defer {
				isUpdating = false
				pendingDevelopmentAccessOnly = nil
			}

			do {
				let response = try await service.updateServerAccessMode(
					developmentAccessOnly: developmentAccessOnly
				)
				self.developmentAccessOnly = response.developmentAccessOnly
				Print("Updated server access mode: development_access_only=\(response.developmentAccessOnly)", category: .network)
			} catch {
				PrintError("Unable to update server access mode", category: .network, error: error)
				badges.present(error: error, title: "Unable to update server access")
			}
		}
	}
}
