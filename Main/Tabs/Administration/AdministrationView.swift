import SwiftUI

struct AdministrationView: View {
	@State private var service = AdministrationService.shared
	@State private var isAdmin = false
	@State private var authority: AccountAuthority = .user
	@State private var pendingModerationCount = 0
	@State private var isSendingTestEmail = false
	@Environment(\.statusBadgeManager) private var badges
	@Environment(\.appPresentation) private var presentation
	@Environment(AppRouter.self) private var router

	var body: some View {
		Group {
			if isAdmin {
				List {
					administrationSections
				}
				.scrollEdgeEffect()

			} else {
				ContentUnavailableView(
					"Administration Unavailable",
					systemImage: "lock",
					description: Text("This account is not an administrator.")
				)
			}
		}
		.appPaperBackground()
		.tint(.accent)
		.minimizingToolbarOnScrollDown()
		.appNavigationTitle("Administration", style: .main, accent: true)
		.task {
			await load()
		}
		.refreshable {
			await load()
		}
		.onReceive(NotificationCenter.default.publisher(for: .administrationDashboardRefreshRequested)) { _ in
			Task {
				await load()
			}
		}
	}

	@ViewBuilder
	private var administrationSections: some View {
		Section("Overview") {
			administrationLink("Statistics", systemImage: "chart.bar", route: .administration(.statistics)) {
				AdministrationStatisticsView()
			}
			administrationLink("Users", systemImage: "person.2", route: .administration(.users)) {
				AdministrationUsersView(closeWideDestination: nil)
			}
		}
		.glurListRowBackground()

		Section {
			administrationLink("User Reports", systemImage: "exclamationmark.bubble", route: .administration(.userReports)) {
				AdministrationUserReportsView()
			}
		} header: {
			HStack {
				Text("Moderation")
				Spacer()
				if pendingModerationCount > 0 {
					Text("\(pendingModerationCount)")
				}
			}
		}
		.glurListRowBackground()

		Section("School Content") {
			administrationLink("School Events", systemImage: "calendar", route: .administration(.schoolEvents)) {
				AdministrationSchoolEventsView(closeWideDestination: nil)
			}
			administrationLink("Event Tags", systemImage: "tag", route: .administration(.eventTags)) {
				AdministrationEventTagsView(closeWideDestination: nil)
			}
			administrationLink("Term Dates", systemImage: "calendar", route: .administration(.calendarEntries(kind: "term"))) {
				AdministrationCalendarEntriesView(kind: "term", closeWideDestination: nil)
			}
			administrationLink("Pupil Free Days", systemImage: "calendar.badge.exclamationmark", route: .administration(.calendarEntries(kind: "noSchool"))) {
				AdministrationCalendarEntriesView(kind: "noSchool", closeWideDestination: nil)
			}
		}
		.glurListRowBackground()

		Section("Notifications") {
			administrationLink("Broadcast Notification", systemImage: "megaphone", route: .administration(.broadcastNotification)) { AdministrationBroadcastNotificationView() }
			administrationLink("Broadcast History", systemImage: "clock.arrow.circlepath", route: .administration(.broadcastHistory)) { AdministrationBroadcastHistoryView() }
			administrationLink("Email Log", systemImage: "envelope.badge", route: .administration(.emailLog)) { AdministrationEmailLogView() }
		}
		.glurListRowBackground()

		Section("Testing") {
			administrationLink("Font Width Test", systemImage: "textformat.size", route: .administration(.fontWidthTest)) {
				AdministrationFontWidthTestView()
			}
		}
		.glurListRowBackground()

		if authority == .systemOwner {
			Section("System Administration") {
				administrationLink("Administrators", systemImage: "person.badge.shield.checkmark", route: .administration(.administrators)) { AdministrationAdministratorsView() }
				administrationLink("App Version", systemImage: "arrow.down.app", route: .administration(.appVersion)) { AdministrationAppVersionView() }
				administrationLink("Debug Testing", systemImage: "testtube.2", route: .administration(.serverAccess)) { AdministrationDevelopmentAccessView() }
				administrationLink("Profile Storage", systemImage: "externaldrive.fill", route: .administration(.profileStorage)) { AdministrationProfileStorageView() }
				administrationLink("Badges", systemImage: "rosette", route: .administration(.specialBadges)) { AdministrationSpecialBadgesView() }
				Button("Send Test Email", systemImage: "envelope") {
					sendTestEmail()
				}
				.disabled(isSendingTestEmail)
			}
			.glurListRowBackground()
		}
	}

	private func sendTestEmail() {
		isSendingTestEmail = true
		Task {
			defer {
				isSendingTestEmail = false
			}
			do {
				try await service.sendTestEmail()
				badges.addBadge(
					id: UUID(),
					title: "Test Email Sent",
					secondaryText: "Sent to omeriadon@outlook.com",
					priority: 3,
					view: .success
				)
			} catch {
				badges.present(error: error, title: "Unable to send test email")
			}
		}
	}

	@ViewBuilder
	private func administrationLink(
		_ title: String,
		systemImage: String,
		route: AppRoute,
		@ViewBuilder destination: () -> some View
	) -> some View {
		if presentation == .iOS {
			NavigationLink {
				destination()
			} label: {
				Label(title, systemImage: systemImage)
			}
		} else {
			let isSelected = router.inspectorRoute == route

			Button {
				if isSelected {
					router.inspectorRoute = nil
				} else {
					router.navigate(to: route)
				}
			} label: {
				HStack {
					Label {
						Text(title)
							.foregroundStyle(isSelected ? .white : .primary)
					} icon: {
						Image(systemName: systemImage)
							.foregroundStyle(isSelected ? .white : .accent)
					}
					Spacer()
					Image(systemName: "chevron.right")
						.foregroundStyle(isSelected ? .white : .secondary)
				}
				.contentShape(Rectangle())
			}
			.listRowBackground(isSelected ? Color.accentColor : nil)
			.buttonStyle(.plain)
			.tint(.accentColor)
		}
	}

	private func load() async {
		do {
			let dashboard = try await service.dashboard()
			isAdmin = dashboard.isAdmin
			authority = dashboard.authority
			pendingModerationCount = dashboard.pendingModerationCount
		} catch {
			isAdmin = false
			authority = .user
			pendingModerationCount = 0
			badges.present(error: error, title: "Unable to refresh administration")
		}
	}
}

extension Notification.Name {
	static let administrationDashboardRefreshRequested = Notification.Name("administrationDashboardRefreshRequested")
}
