
import Defaults
import SwiftUI

struct CompactAppShell: View {
	@Environment(AppRouter.self) private var router
	@State private var networkManager = NetworkManager.shared
	@Default(.accountProfile) private var accountProfile

	@Default(.incomingFriendRequests) private var incomingFriendRequests

	var body: some View {
		@Bindable var router = router

		Group {
			if Platform.current == .iOS {
				UIKitTabView(selection: $router.selectedTab, items: tabItems(router: router))
			} else {
				TabView(selection: $router.selectedTab) {
					ForEach(tabItems(router: router), id: \.value) { item in
						Tab(item.title, systemImage: item.systemImage, value: item.value) {
							item.content
						}
						.badge(item.badge ?? "")
					}
				}
			}
		}
		.ignoresSafeArea()
		.onReceive(NotificationCenter.default.publisher(for: .openTimetableTab)) { _ in
			router.selectRoot(.timetable)
		}
		.onReceive(NotificationCenter.default.publisher(for: .openSettingsTab)) { _ in
			router.selectRoot(.settings)
		}
		.onReceive(NotificationCenter.default.publisher(for: .selectAppRoot)) { notification in
			guard let destination = notification.object as? AppRootDestination else {
				return
			}
			router.selectRoot(destination)
		}
		.onReceive(NotificationCenter.default.publisher(for: .administrationAuthorityInvalidated)) { _ in
			if router.selectedTab == .administration {
				router.selectRoot(.timetable)
			}
			Task {
				_ = try? await SessionStore.shared.refreshProfile()
			}
		}
		.onChange(of: canShowAdministration) { _, canShowAdministration in
			guard !canShowAdministration,
			      router.selectedTab == .administration
			else {
				return
			}
			router.selectRoot(.timetable)
		}
		.task {
			networkManager.startMonitoring()
		}
	}

	private var canShowAdministration: Bool {
		accountProfile?.authority.isAdministrator ?? false
	}

	private func tabItems(router: AppRouter) -> [UIKitTabItem] {
		[
			UIKitTabItem(
				title: "Timetable",
				systemImage: "calendar.day.timeline.left",
				value: .timetable,
				badge: nil,
				content: AnyView(NavigationStack(path: Binding(get: { router.timetablePath }, set: { router.timetablePath = $0 })) {
					TimetableView()
						.navigationDestination(for: AppRoute.self) { route in
							CompactRouteDestinationView(route: route)
						}
				})
			),
			UIKitTabItem(
				title: "Friends",
				systemImage: "person.2",
				value: .friends,
				badge: incomingFriendRequests.isEmpty ? nil : "\(incomingFriendRequests.count)",
				content: AnyView(NavigationStack(path: Binding(get: { router.friendsPath }, set: { router.friendsPath = $0 })) {
					FriendsView()
						.navigationDestination(for: AppRoute.self) { route in
							CompactRouteDestinationView(route: route)
						}
				})
			),
			UIKitTabItem(
				title: "Grades",
				systemImage: "chart.bar.xaxis",
				value: .grades,
				badge: nil,
				content: AnyView(NavigationStack(path: Binding(get: { router.gradesPath }, set: { router.gradesPath = $0 })) {
					GradeTrackerView()
						.navigationDestination(for: AppRoute.self) { route in
							CompactRouteDestinationView(route: route)
						}
				})
			),
			UIKitTabItem(
				title: "Settings",
				systemImage: "gear",
				value: .settings,
				badge: nil,
				content: AnyView(NavigationStack(path: Binding(get: { router.settingsPath }, set: { router.settingsPath = $0 })) {
					SettingsView()
						.navigationDestination(for: AppRoute.self) { route in
							CompactRouteDestinationView(route: route)
						}
				})
			),
		].appendingIf(canShowAdministration, UIKitTabItem(
			title: "Admin",
			systemImage: "calendar.badge.lock",
			value: .administration,
			badge: nil,
			content: AnyView(NavigationStack(path: Binding(get: { router.administrationPath }, set: { router.administrationPath = $0 })) {
				AdministrationView()
					.navigationDestination(for: AppRoute.self) { route in
						CompactRouteDestinationView(route: route)
					}
			})
		))
	}
}

#Preview {
	CompactAppShell()
		.environment(AppRouter())
}
