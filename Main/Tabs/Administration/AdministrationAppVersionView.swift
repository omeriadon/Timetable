import SwiftUI

struct AdministrationAppVersionView: View {
	@State private var service = AdministrationService.shared
	@State private var appVersion = "0.0.0"
	@State private var appBuild = 0
	@State private var macVersion = "0.0.0"
	@State private var macBuild = 0
	@State private var isLoading = true
	@State private var isSaving = false
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		Form {
			Section("iOS and iPadOS") {
				TextField("Version", text: $appVersion)
				TextField("Build", value: $appBuild, format: .number)
			}

			Section("macOS") {
				TextField("Version", text: $macVersion)
				TextField("Build", value: $macBuild, format: .number)
			}

			Section {
				Button("Save App Versions", systemImage: "checkmark", role: .confirm) {
					save()
				}
				.buttonStyle(.glassProminent)
				.disabled(isLoading || isSaving || !versionsAreValid)
			}
		}
		.appGroupedFormStyle()
		.appNavigationTitle("App Version", accent: true)
		.disabled(isLoading)
		.task {
			await load()
		}
		.refreshable {
			await load()
		}
	}

	private var versionsAreValid: Bool {
		[appVersion, macVersion].allSatisfy { value in
			let components = value.split(separator: ".", omittingEmptySubsequences: false)
			return components.count == 3
				&& components.allSatisfy { !$0.isEmpty && $0.allSatisfy(\.isNumber) }
		}
			&& appBuild >= 0
			&& macBuild >= 0
	}

	private func load() async {
		isLoading = true
		defer {
			isLoading = false
		}
		do {
			let response = try await service.appVersionRequirement()
			apply(response)
		} catch {
			badges.present(error: error, title: "Unable to load app versions")
		}
	}

	private func save() {
		isSaving = true
		Task {
			defer {
				isSaving = false
			}
			do {
				let response = try await service.updateAppVersionRequirement(
					AppVersionRequirementUpdateRequest(
						appVersion: appVersion,
						appBuild: appBuild,
						macVersion: macVersion,
						macBuild: macBuild
					)
				)
				apply(response)
				badges.addBadge(
					id: UUID(),
					title: "App Versions Saved",
					priority: 3,
					view: .success
				)
			} catch {
				badges.present(error: error, title: "Unable to save app versions")
			}
		}
	}

	private func apply(_ response: AppVersionRequirementResponse) {
		appVersion = response.appVersion
		appBuild = response.appBuild
		macVersion = response.macVersion
		macBuild = response.macBuild
	}
}
