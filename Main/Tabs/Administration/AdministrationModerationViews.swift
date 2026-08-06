import SwiftUI

struct AdministrationFriendshipDateChangeRequestsView: View {
	@State private var service = AdministrationService.shared
	@State private var requests: [AdministrationFriendshipDateChangeRequest] = []
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List {
			ForEach(requests) { request in
				Section(request.requesterDisplayName ?? request.requesterID.uuidString) {
					LabeledContent("Requested date") {
						Text(request.requestedDate, format: .dateTime.day().month().year())
					}
					LabeledContent("Status", value: statusLabel(for: request.action))
					if request.action == .pending {
						Button("Approve", systemImage: "checkmark", role: .confirm) {
							resolve(request, action: .approved)
						}
						.buttonStyle(.glassProminent)
						Button("Reject", systemImage: "xmark", role: .destructive) {
							resolve(request, action: .rejected)
						}
					}
				}
			}
		}
		.appNavigationTitle("Friends-Since Requests")
		.task { await load() }
		.refreshable { await load() }
	}

	private func load() async {
		do {
			requests = try await service.friendshipDateChangeRequests()
		} catch {
			badges.present(error: error, title: "Unable to load requests")
		}
	}

	private func resolve(_ request: AdministrationFriendshipDateChangeRequest, action: ModerationAction) {
		Task {
			do {
				let updated = try await service.resolveFriendshipDateChangeRequest(id: request.id, action: action)
				if let index = requests.firstIndex(where: { $0.id == updated.id }) {
					requests[index] = updated
				}
			} catch {
				badges.present(error: error, title: "Unable to resolve request")
			}
		}
	}
}

struct AdministrationUserReportsView: View {
	@State private var service = AdministrationService.shared
	@State private var reports: [AdministrationUserReport] = []
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List {
			ForEach(reports) { report in
				Section(report.reportedUserDisplayName ?? report.reportedUserID.uuidString) {
					LabeledContent("Reported by", value: report.reporterDisplayName ?? report.reporterID.uuidString)
					LabeledContent("Status", value: statusLabel(for: report.action))
					if report.action == .pending {
						Button("Do Nothing", systemImage: "checkmark", role: .confirm) {
							resolve(report, action: .noAction)
						}
						.buttonStyle(.glassProminent)
						Button("Delete Account", systemImage: "trash", role: .destructive) {
							resolve(report, action: .accountDeleted)
						}
					}
				}
			}
		}
		.appNavigationTitle("User Reports")
		.task { await load() }
		.refreshable { await load() }
	}

	private func load() async {
		do {
			reports = try await service.userReports()
		} catch {
			badges.present(error: error, title: "Unable to load reports")
		}
	}

	private func resolve(_ report: AdministrationUserReport, action: ModerationAction) {
		Task {
			do {
				let updated = try await service.resolveUserReport(id: report.id, action: action)
				if let index = reports.firstIndex(where: { $0.id == updated.id }) {
					reports[index] = updated
				}
			} catch {
				badges.present(error: error, title: "Unable to resolve report")
			}
		}
	}
}

private func statusLabel(for action: ModerationAction) -> String {
	switch action {
		case .pending:
			"Pending"
		case .noAction:
			"No action"
		case .accountDeleted:
			"Account deleted"
		case .approved:
			"Approved"
		case .rejected:
			"Rejected"
	}
}
