import SwiftUI

struct AdministrationEmailLogView: View {
	@State private var records: [AdministrationEmailDeliveryRecord] = []
	@State private var service = AdministrationService.shared
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List {
			if records.isEmpty {
				ContentUnavailableView(
					"No Emails Logged",
					systemImage: "envelope.open"
				)
			} else {
				ForEach(records) { record in
					Section {
						LabeledContent("Recipient", value: record.recipient)
						LabeledContent("Subject", value: record.subject)
						LabeledContent("Status") {
							Label(
								record.status.capitalized,
								systemImage: statusSymbol(for: record.status)
							)
						}

						if let createdAt = record.createdAt {
							LabeledContent("Created") {
								Text(createdAt, format: .dateTime.minute().hour().day().month().year())
							}
						}

						if let failureReason = record.failureReason {
							LabeledContent("Failure", value: failureReason)
						}

						Text(record.body)
							.textSelection(.enabled)
					} header: {
						Text(record.subject)
					}
					.glurListRowBackground()
				}
			}
		}
		.appPaperBackground()
		.appNavigationTitle("Email Log")
		.task { await load() }
		.refreshable { await load() }
	}

	private func load() async {
		do {
			records = try await service.emailLog()
		} catch {
			badges.present(error: error, title: "Unable to load email log")
		}
	}

	private func statusSymbol(for status: String) -> String {
		switch status {
			case "delivered":
				"checkmark.circle"
			case "failed":
				"exclamationmark.triangle"
			default:
				"clock"
		}
	}
}
