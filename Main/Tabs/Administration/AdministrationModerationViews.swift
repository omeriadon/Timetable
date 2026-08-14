import SwiftUI

struct AdministrationUserReportsView: View {
	@State private var service = AdministrationService.shared
	@State private var reports: [AdministrationUserReport] = []
	@State private var searchText = ""
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List {
			ForEach(filteredReports) { report in
				Section {
					LabeledContent(
						"Reported user",
						value: report.reportedUserDisplayName ?? report.reportedUserID.uuidString
					)
					LabeledContent(
						"Reported by",
						value: report.reporterDisplayName ?? report.reporterID.uuidString
					)
					LabeledContent("Status", value: statusLabel(for: report.action))

					if let createdAt = report.createdAt {
						LabeledContent("Reported date") {
							Text(createdAt, format: .dateTime.minute().hour().day().month().year())
						}
					}

					if report.action == .pending {
						GlassEffectContainer {
							HStack {
								Button("Do Nothing", systemImage: "checkmark", role: .confirm) {
									resolve(report, action: .noAction)
								}
								.foregroundStyle(.primary)
								.buttonStyle(.glassProminent)
								.buttonSizing(.flexible)

								Button("Delete Account", systemImage: "trash", role: .destructive) {
									resolve(report, action: .accountDeleted)
								}
								.buttonStyle(.glassProminent)
								.buttonSizing(.flexible)
								.foregroundStyle(.primary)
							}
						}
					}
				}
				.glurListRowBackground()
			}
		}
		.appPaperBackground()
		.appNavigationTitle("User Reports")
		.searchable(text: $searchText, prompt: "Search reports")
		.task { await load() }
		.refreshable { await load() }
	}

	private var filteredReports: [AdministrationUserReport] {
		let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !query.isEmpty else { return reports }
		return reports.filter {
			($0.reportedUserDisplayName ?? "").localizedCaseInsensitiveContains(query)
				|| ($0.reporterDisplayName ?? "").localizedCaseInsensitiveContains(query)
				|| $0.reportedUserID.uuidString.localizedCaseInsensitiveContains(query)
				|| $0.reporterID.uuidString.localizedCaseInsensitiveContains(query)
				|| statusLabel(for: $0.action).localizedCaseInsensitiveContains(query)
		}
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
