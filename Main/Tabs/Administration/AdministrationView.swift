import SwiftUI

struct AdministrationView: View {
	@State private var service = AdministrationService.shared
	@State private var isAdmin = false
	@State private var authority: AccountAuthority = .user
	@Environment(\.statusBadgeManager) private var badges
	@Environment(\.appPresentation) private var presentation
	@Environment(AppRouter.self) private var router

	var body: some View {
		Group {
			if isAdmin {
				#if os(macOS)
					Form {
						administrationSections
					}
					.formStyle(.grouped)
					.scrollContentBackground(.hidden)
				#else
					List {
						administrationSections
					}
					.scrollEdgeEffect()
				#endif
			} else {
				ContentUnavailableView(
					"Administration Unavailable",
					systemImage: "lock",
					description: Text("This account is not an administrator.")
				)
			}
		}
		.tint(.accent)
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
		Section {
			administrationLink("School Events", systemImage: "calendar", route: .administration(.schoolEvents)) { AdministrationSchoolEventsView() }
			administrationLink("Event Tags", systemImage: "tag", route: .administration(.eventTags)) { AdministrationEventTagsView() }
			administrationLink("Term Dates", systemImage: "calendar", route: .administration(.calendarEntries(kind: "term"))) { AdministrationCalendarEntriesView(kind: "term") }
			administrationLink("Pupil Free Days", systemImage: "calendar.badge.exclamationmark", route: .administration(.calendarEntries(kind: "noSchool"))) { AdministrationCalendarEntriesView(kind: "noSchool") }
			administrationLink("Users", systemImage: "person.2", route: .administration(.users)) { AdministrationUsersView() }
			administrationLink("Broadcast Notification", systemImage: "megaphone", route: .administration(.broadcastNotification)) { AdministrationBroadcastNotificationView() }
			administrationLink("Broadcast History", systemImage: "clock.arrow.circlepath", route: .administration(.broadcastHistory)) { AdministrationBroadcastHistoryView() }
		}

		if authority == .systemOwner {
			Section("System Administration") {
				administrationLink("Administrators", systemImage: "person.badge.shield.checkmark", route: .administration(.administrators)) { AdministrationAdministratorsView() }
				administrationLink("Debug Testing", systemImage: "testtube.2", route: .administration(.serverAccess)) { AdministrationDevelopmentAccessView() }
				administrationLink("Profile Storage", systemImage: "externaldrive.fill", route: .administration(.profileStorage)) { AdministrationProfileStorageView() }
				administrationLink("Badges", systemImage: "rosette", route: .administration(.specialBadges)) { AdministrationSpecialBadgesView() }
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
					Label(title, systemImage: systemImage)
					Spacer()
					Image(systemName: "chevron.right")
						.foregroundStyle(isSelected ? .white : .secondary)
				}
				.contentShape(Rectangle())
			}
			.foregroundStyle(isSelected ? .white : .primary)
			.listRowBackground(isSelected ? Color.accentColor : nil)
		}
	}

	private func load() async {
		do {
			let dashboard = try await service.dashboard()
			isAdmin = dashboard.isAdmin
			authority = dashboard.authority
		} catch {
			isAdmin = false
			authority = .user
			badges.present(error: error, title: "Unable to refresh administration")
		}
	}
}

extension Notification.Name {
	static let administrationDashboardRefreshRequested = Notification.Name("administrationDashboardRefreshRequested")
}
