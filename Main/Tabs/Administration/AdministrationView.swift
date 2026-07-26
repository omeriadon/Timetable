import SwiftUI

struct AdministrationView: View {
	@State private var service = AdministrationService.shared
	@State private var isAdmin = false

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
								AdministrationCalendarEntriesView(kind: "term")
							} label: {
								Label("Term Dates", systemImage: "calendar")
							}

							NavigationLink {
								AdministrationCalendarEntriesView(kind: "noSchool")
							} label: {
								Label("No-School Days", systemImage: "calendar.badge.exclamationmark")
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
						}
					}
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
		} catch {
			isAdmin = false
		}
	}
}
