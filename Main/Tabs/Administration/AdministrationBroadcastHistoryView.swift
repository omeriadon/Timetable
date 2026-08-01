import SwiftUI

struct AdministrationBroadcastHistoryView: View {
	@State private var service = AdministrationService.shared
	@State private var records: [BroadcastNotificationHistoryResponse] = []
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List(records) { record in
			NavigationLink {
				AdministrationBroadcastHistoryDetailView(
					record: record,
					delete: delete
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
		do {
			records = try await service.broadcastNotifications()
		} catch {
			badges.present(error: error, title: "Unable to refresh broadcast history")
		}
	}

	private func delete(_ record: BroadcastNotificationHistoryResponse) async throws -> BroadcastNotificationHistoryResponse {
		let updated = try await service.deleteBroadcastNotification(id: record.id)
		if let index = records.firstIndex(where: { $0.id == updated.id }) {
			records[index] = updated
		}
		return updated
	}
}

private struct AdministrationBroadcastHistoryDetailView: View {
	let record: BroadcastNotificationHistoryResponse
	let delete: (BroadcastNotificationHistoryResponse) async throws -> BroadcastNotificationHistoryResponse

	@Environment(\.dismiss) private var dismiss
	@Environment(\.statusBadgeManager) private var badges
	@State private var showsDeleteConfirmation = false
	@State private var currentRecord: BroadcastNotificationHistoryResponse

	init(
		record: BroadcastNotificationHistoryResponse,
		delete: @escaping (BroadcastNotificationHistoryResponse) async throws -> BroadcastNotificationHistoryResponse
	) {
		self.record = record
		self.delete = delete
		_currentRecord = State(initialValue: record)
	}

	var body: some View {
		Form {
			Section("Message") {
				LabeledContent("Title", value: currentRecord.title)
				LabeledContent("Subtitle", value: currentRecord.subtitle ?? "—")
				LabeledContent("Body", value: currentRecord.body ?? "—")
			}

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
		}
		.appNavigationTitle(currentRecord.isDeleted ? "Deleted Broadcast" : "Broadcast", accent: true)
		.safeAreaBar(edge: .bottom) {
			if !currentRecord.isDeleted {
				Button("Delete Notification", systemImage: "trash", role: .destructive) {
					showsDeleteConfirmation = true
				}
				.buttonStyle(.glassProminent)
				.tint(.red)
			}
		}
		.confirmationDialog("Delete Notification?", isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
			Button("Delete Notification", systemImage: "trash", role: .destructive) {
				Task {
					do {
						currentRecord = try await delete(currentRecord)
					} catch {
						badges.present(error: error, title: "Unable to delete notification")
					}
				}
			}
		} message: {
			Text("This marks the broadcast as deleted and sends a removal push to subscribed devices.")
		}
	}
}
