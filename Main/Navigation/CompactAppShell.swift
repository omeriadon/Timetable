#if os(iOS)
	import Defaults
	import SwiftUI

	struct CompactAppShell: View {
		@Environment(AppRouter.self) private var router
		@State private var networkManager = NetworkManager.shared
		@Default(.accountProfile) private var accountProfile

		@Default(.incomingFriendRequests) private var incomingFriendRequests

		var body: some View {
			@Bindable var router = router

			TabView(selection: $router.selectedTab) {
				Tab(
					"Timetable",
					systemImage: "calendar.day.timeline.left",
					value: MainTab.timetable
				) {
					NavigationStack(path: $router.timetablePath) {
						TimetableView()
							.navigationDestination(for: AppRoute.self) { route in
								CompactRouteDestinationView(route: route)
							}
					}
				}

				Tab(
					"Friends",
					systemImage: "person.2",
					value: MainTab.friends
				) {
					NavigationStack(path: $router.friendsPath) {
						FriendsView()
							.navigationDestination(for: AppRoute.self) { route in
								CompactRouteDestinationView(route: route)
							}
					}
				}
				.badge(incomingFriendRequests.count)

				Tab(
					"Settings",
					systemImage: "gear",
					value: MainTab.settings
				) {
					NavigationStack(path: $router.settingsPath) {
						SettingsView()
							.navigationDestination(for: AppRoute.self) { route in
								CompactRouteDestinationView(route: route)
							}
					}
				}

				if canShowAdministration {
					Tab(
						"Admin",
						systemImage: "calendar.badge.lock",
						value: MainTab.administration
					) {
						NavigationStack(path: $router.administrationPath) {
							AdministrationView()
								.navigationDestination(for: AppRoute.self) { route in
									CompactRouteDestinationView(route: route)
								}
						}
					}
				}
			}
			.ignoresSafeArea()
			.animation(.easeInOut(duration: 0.1), value: router.selectedTab)
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
	}

	#Preview {
		CompactAppShell()
			.environment(AppRouter())
	}
#endif
