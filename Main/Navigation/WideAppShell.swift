import Defaults
import SwiftUI

struct WideAppShell: View {
	@Environment(AppRouter.self) private var router
	@Binding var expanded: WindowMode
	@Default(.accountProfile) private var accountProfile

	var body: some View {
		@Bindable var router = router

		NavigationSplitView(columnVisibility: sidebarVisibility) {
			List(selection: sidebarSelection) {
				Section("Timetable") {
					sidebarRoot("Timetable", systemImage: "calendar.day.timeline.left", destination: .timetable)
					sidebarRoot("Friends", systemImage: "person.2", destination: .friends)
				}

				Section("Personal") {
					sidebarRoute("Account", systemImage: "person.crop.circle", route: .settings(.account))
					sidebarRoute("Updates & Notifications", systemImage: "switch.2", route: .settings(.updatesAndNotifications))
					sidebarRoute("Event Tags", systemImage: "tag", route: .settings(.tagSubscriptions))
					sidebarRoot("Settings", systemImage: "gear", destination: .settings)
				}

				if accountProfile?.authority.isAdministrator == true {
					Section("Administration") {
						sidebarRoot("Administration", systemImage: "calendar.badge.lock", destination: .administration)
						sidebarRoute("School Events", systemImage: "calendar", route: .administration(.schoolEvents))
						sidebarRoute("Users", systemImage: "person.2", route: .administration(.users))
					}
				}
			}
			.navigationTitle("Timetable")
			.listStyle(.sidebar)
		} detail: {
			NavigationStack(path: $router.sidebarPath) {
				WideRootDestinationView(
					destination: router.selectedSidebarDestination,
					expanded: $expanded
				)
				.navigationDestination(for: AppRoute.self) { route in
					WideRouteDestinationView(route: route)
				}
			}
		}
		.inspector(isPresented: inspectorPresented) {
			if let route = router.inspectorRoute {
				WideRouteDestinationView(route: route)
					.inspectorColumnWidth(min: 360, ideal: 480, max: 680)
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .openTimetableTab)) { _ in
			router.selectRoot(.timetable)
		}
		.onReceive(NotificationCenter.default.publisher(for: .openSettingsTab)) { _ in
			router.selectRoot(.settings)
		}
	}

	private var sidebarSelection: Binding<AppRootDestination?> {
		Binding(
			get: { router.selectedSidebarDestination },
			set: { destination in
				guard let destination else {
					return
				}
				router.selectRoot(destination)
			}
		)
	}

	private var sidebarVisibility: Binding<NavigationSplitViewVisibility> {
		Binding(
			get: { router.sidebarVisibility.navigationSplitViewVisibility },
			set: { router.sidebarVisibility = AppSidebarVisibility($0) }
		)
	}

	private var inspectorPresented: Binding<Bool> {
		Binding(
			get: { router.inspectorRoute != nil },
			set: { presented in
				if !presented {
					router.inspectorRoute = nil
				}
			}
		)
	}

	private func sidebarRoot(
		_ title: String,
		systemImage: String,
		destination: AppRootDestination
	) -> some View {
		Label(title, systemImage: systemImage)
			.tag(destination)
	}

	private func sidebarRoute(
		_ title: String,
		systemImage: String,
		route: AppRoute
	) -> some View {
		Button {
			router.navigate(to: route)
		} label: {
			Label(title, systemImage: systemImage)
		}
		.buttonStyle(.plain)
	}
}
