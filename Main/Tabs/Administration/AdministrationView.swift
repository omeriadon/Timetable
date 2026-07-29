import SwiftUI

struct AdministrationView: View {
	@State private var service = AdministrationService.shared
	@State private var isAdmin = false
	@State private var authority: AccountAuthority = .user

	var body: some View {
		NavigationStack {
			Group {
				if isAdmin {
					List {
						Section {
							NavigationLink {
								AdministrationSchoolEventsView()
							} label: {
								Label("School Events", systemImage: "calendar")
							}

							NavigationLink {
								AdministrationEventTagsView()
							} label: {
								Label("Event Tags", systemImage: "tag")
							}

							NavigationLink {
								AdministrationCalendarEntriesView(kind: "term")
							} label: {
								Label("Term Dates", systemImage: "calendar")
							}

							NavigationLink {
								AdministrationCalendarEntriesView(kind: "noSchool")
							} label: {
								Label("Pupil Free Days", systemImage: "calendar.badge.exclamationmark")
							}

							NavigationLink {
								AdministrationUsersView()
							} label: {
								Label("Users", systemImage: "person.2")
							}

							NavigationLink {
								AdministrationBroadcastNotificationView()
							} label: {
								Label("Broadcast Notification", systemImage: "megaphone")
							}

							NavigationLink {
								AdministrationBroadcastHistoryView()
							} label: {
								Label("Broadcast History", systemImage: "clock.arrow.circlepath")
							}
						}

						if authority == .systemOwner {
							Section("Owner Administration") {
								NavigationLink {
									AdministrationAdministratorsView()
								} label: {
									Label("Administrators", systemImage: "person.badge.shield.checkmark")
								}

								NavigationLink {
									AdministrationDevelopmentAccessView()
								} label: {
									Label("Debug Testing", systemImage: "testtube.2")
								}
							}
						}
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
			.appNavigationTitle("Administration", style: .main, accent: true)
			.task {
				await load()
			}
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
		}
	}
}
