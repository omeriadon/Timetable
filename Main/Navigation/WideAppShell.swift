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
				sidebarRoot("Timetable", systemImage: "calendar.day.timeline.left", destination: .timetable)
				sidebarRoot("Friends", systemImage: "person.2", destination: .friends)
				sidebarRoot("Settings", systemImage: "gear", destination: .settings)

				if accountProfile?.authority.isAdministrator == true {
					sidebarRoot("Administration", systemImage: "calendar.badge.lock", destination: .administration)
				}
			}
			.appNavigationTitle("Timetable")
			.listStyle(.sidebar)
			.scrollEdgeEffectStyle(.soft, for: .all)
			.navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 210)
		} detail: {
			NavigationStack(path: $router.sidebarPath) {
				ZStack {
					WideRootDestinationView(
						destination: router.selectedSidebarDestination,
						expanded: $expanded
					)
					.id(router.selectedSidebarDestination)
					.transition(.opacity)
				}
				.animation(.easeInOut, value: router.selectedSidebarDestination)
				.navigationDestination(for: AppRoute.self) { route in
					WideRouteDestinationView(route: route)
						.transition(.opacity)
				}
			}
			.navigationSplitViewColumnWidth(min: 540, ideal: 700, max: 860)
		}
		.inspector(isPresented: inspectorPresented) {
			if let route = router.inspectorRoute {
				WideRouteDestinationView(route: route)
					.inspectorColumnWidth(min: 400, ideal: 430, max: 460)
			}
		}
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
}
