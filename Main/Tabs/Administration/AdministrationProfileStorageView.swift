import SwiftUI

struct AdministrationProfileStorageView: View {
	@State private var service = AdministrationService.shared
	@State private var quota: ProfileStorageQuotaResponse?
	@Environment(\.statusBadgeManager) private var statusBadges

	var body: some View {
		List {
			if let quota {
				Section("Storage") {
					quotaProgress(
						value: quota.storedBytes + quota.reservedBytes,
						limit: quota.storageLimitBytes
					)

					LabeledContent("Stored", value: formattedBytes(quota.storedBytes))
					LabeledContent("Reserved", value: formattedBytes(quota.reservedBytes))
					LabeledContent("Limit", value: formattedBytes(quota.storageLimitBytes))
				}

				Section("Monthly Operations") {
					quotaProgress(
						value: Int64(quota.monthlyOperations),
						limit: Int64(quota.monthlyOperationLimit)
					)

					LabeledContent("Used", value: quota.monthlyOperations.formatted())
					LabeledContent("Limit", value: quota.monthlyOperationLimit.formatted())
					LabeledContent("Write Cutoff", value: quota.monthlyWriteCutoff.formatted())
				}

				Section("Mutation State") {
					LabeledContent(
						"Profile Photo Changes",
						value: quota.writesDisabled ? "Disabled" : "Available"
					)
				}
			} else {
				ProgressView("Loading profile storage")
			}
		}
		.scrollEdgeEffect()
		.appNavigationTitle("Profile Storage", accent: true)
		.refreshable {
			await load()
		}
		.task {
			await load()
		}
	}

	private func quotaProgress(value: Int64, limit: Int64) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			ProgressView(
				value: Double(value),
				total: Double(max(1, limit))
			)

			Text("\(percentage(value: value, limit: limit))% used")
				.font(.footnote)
				.foregroundStyle(.secondary)
		}
	}

	private func load() async {
		do {
			quota = try await service.profileStorageQuota()
		} catch {
			statusBadges.present(error: error, title: "Unable to load profile storage")
		}
	}

	private func formattedBytes(_ bytes: Int64) -> String {
		ByteCountFormatter.string(
			fromByteCount: bytes,
			countStyle: .file
		)
	}

	private func percentage(value: Int64, limit: Int64) -> Int {
		guard limit > 0 else {
			return 0
		}
		return Int((Double(value) / Double(limit) * 100).rounded())
	}
}
