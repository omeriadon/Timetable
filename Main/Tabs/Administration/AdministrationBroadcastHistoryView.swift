import SwiftUI

struct AdministrationBroadcastHistoryView: View {
	@State private var service = AdministrationService.shared
	@State private var records: [BroadcastNotificationHistoryResponse] = []

	var body: some View {
		List(records) { record in
			DisclosureGroup {
				LabeledContent("Sender", value: record.senderEmail)
				LabeledContent("Eligible", value: String(record.eligibleDeviceCount))
				LabeledContent("Delivered", value: String(record.deliveredDeviceCount))
				LabeledContent("Invalidated", value: String(record.invalidatedDeviceCount))
				LabeledContent("Failed", value: String(record.failedDeviceCount))
				if let subtitle = record.subtitle {
					LabeledContent("Subtitle", value: subtitle)
				}
				if let body = record.body {
					Text(body)
						.textSelection(.enabled)
				}
				if let failureSummary = record.failureSummary {
					LabeledContent("Failure", value: failureSummary)
				}
			} label: {
				Label {
					VStack(alignment: .leading, spacing: 3) {
						Text(record.title)
							.foregroundStyle(.primary)
						Text(record.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown date")
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				} icon: {
					Image(systemName: record.deliveryState == .failed ? "exclamationmark.triangle" : "megaphone")
				}
			}
		}
		.scrollEdgeEffect()
		.appNavigationTitle("Broadcast History", accent: true)
		.task {
			await load()
		}
		.refreshable {
			await load()
		}
	}

	private func load() async {
		records = (try? await service.broadcastNotifications()) ?? records
	}
}
