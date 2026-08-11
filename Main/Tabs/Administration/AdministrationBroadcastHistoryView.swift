import SwiftUI

struct AdministrationBroadcastHistoryView: View {
	@State private var service = AdministrationService.shared
	@State private var records: [BroadcastNotificationHistoryResponse] = []
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List(records) { record in
			NavigationLink {
				AdministrationBroadcastHistoryDetailView(
					record: record
				)
			} label: {
				Label {
					VStack(alignment: .leading, spacing: 3) {
						Text(record.title)
						Text(record.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown date")
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				} icon: {
					Image(systemName: record.isDeleted ? "trash" : record.deliveryState == .failed ? "exclamationmark.triangle" : "megaphone")
				}
			}
			.glurListRowBackground()
		}
		.appPaperBackground()
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
		do {
			records = try await service.broadcastNotifications()
		} catch {
			badges.present(error: error, title: "Unable to refresh broadcast history")
		}
	}
}

private struct AdministrationBroadcastHistoryDetailView: View {
	let record: BroadcastNotificationHistoryResponse

	@State private var service = AdministrationService.shared
	@Environment(\.statusBadgeManager) private var badges
	@State private var showsDeleteConfirmation = false
	@State private var currentRecord: BroadcastNotificationHistoryResponse

	init(
		record: BroadcastNotificationHistoryResponse
	) {
		self.record = record
		_currentRecord = State(initialValue: record)
	}

	var body: some View {
		List {
			Section("Message") {
				LabeledContent("Title", value: currentRecord.title)
				LabeledContent("Subtitle", value: currentRecord.subtitle ?? "—")
				LabeledContent("Body", value: currentRecord.body ?? "—")
			}
			.glurListRowBackground()

			Section("Delivery") {
				LabeledContent("Sender", value: currentRecord.senderEmail)
				LabeledContent("Eligible", value: String(currentRecord.eligibleDeviceCount))
				LabeledContent("Delivered", value: String(currentRecord.deliveredDeviceCount))
				LabeledContent("Invalidated", value: String(currentRecord.invalidatedDeviceCount))
				LabeledContent("Failed", value: String(currentRecord.failedDeviceCount))
				if let failureSummary = currentRecord.failureSummary {
					LabeledContent("Failure", value: failureSummary)
				}
			}
			.glurListRowBackground()

			if !currentRecord.isDeleted {
				Button("Delete Notification", systemImage: "trash", role: .destructive) {
					showsDeleteConfirmation = true
				}
				.buttonStyle(.glassProminent)
				.tint(.red)
				.foregroundStyle(.red)
				.alert("Delete Notification?", isPresented: $showsDeleteConfirmation) {
					Button("Delete Notification", systemImage: "trash", role: .destructive) {
						Task {
							do {
								currentRecord = try await service.deleteBroadcastNotification(id: currentRecord.id)
							} catch {
								badges.present(error: error, title: "Unable to delete notification")
							}
						}
					}
				} message: {
					Text("This marks the broadcast as deleted and sends a removal push to subscribed devices.")
				}
				.glurListRowBackground()
			}
		}
		.appPaperBackground()
		.appNavigationTitle(currentRecord.isDeleted ? "Deleted Broadcast" : "Broadcast", accent: true)
	}
}
