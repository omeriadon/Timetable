import Defaults
import SwiftUI

struct WideAppShell: View {
	@Environment(AppRouter.self) private var router
	@Default(.accountProfile) private var accountProfile
	@Default(.incomingFriendRequests) private var incomingFriendRequests

	var body: some View {
		@Bindable var router = router

		NavigationSplitView(columnVisibility: sidebarVisibility) {
			List {
				Section {
					sidebarRoot("Today", systemImage: "calendar.day.timeline.left", destination: .timetableToday)
					sidebarRoot("Week", systemImage: "7.calendar", destination: .timetableWeek)
					sidebarRoot("Planner", systemImage: "pencil.and.list.clipboard", destination: .timetablePlanner)
				}

				Section {
					sidebarRoot("Friends", systemImage: "person.2", destination: .friends)
						.badge(incomingFriendRequests.count)
				}

				Section {
					sidebarRoot("Grades", systemImage: "chart.bar.xaxis", destination: .grades)
				}
			}
			.safeAreaBar(edge: .bottom, spacing: 0) {
				VStack(spacing: 2) {
					sidebarRoot("Settings", systemImage: "gear", destination: .settings)

					if accountProfile?.authority.isAdministrator == true {
						sidebarRoot(
							"Administration",
							systemImage: "calendar.badge.lock",
							destination: .administration
						)
					}
				}
				.padding(.horizontal, 8)
				.padding(.vertical, 6)
			}
			.appNavigationTitle(router.presentation == .iOS ? "Timetable" : "")
			.listStyle(.sidebar)
			.scrollContentBackground(.hidden)
			.background(.clear)
			.scrollEdgeEffectStyle(.soft, for: .all)
			.navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
		} detail: {
			NavigationStack(path: $router.sidebarPath) {
				WideRootDestinationView(destination: router.selectedSidebarDestination)
					.navigationDestination(for: AppRoute.self) { route in
						WideRouteDestinationView(
							route: route,
							close: closeDetailDestination,
							closeWideDestination: closeDetailDestination
						)
					}
			}
			.background(.clear)
			.navigationSplitViewColumnWidth(min: 540, ideal: 700, max: 860)
		}
		.inspector(isPresented: inspectorPresented) {
			if let route = router.inspectorRoute {
				NavigationStack(path: $router.inspectorPath) {
					WideRouteDestinationView(
						route: route,
						showsCloseButton: true,
						close: dismissInspector,
						closeWideDestination: closeInspectorDestination
					)
					.navigationDestination(for: AppRoute.self) { destination in
						WideRouteDestinationView(
							route: destination,
							close: dismissInspector,
							closeWideDestination: closeInspectorDestination
						)
					}
				}
				.inspectorColumnWidth(min: 400, ideal: 500, max: 700)
			}
		}
		.scrollContentBackground(.hidden)
		.background {
			if !router.isShowingAbout {
				AppPaperBackground()
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .openTimetableTab)) { _ in
			router.selectRoot(.timetableToday)
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

	private func closeInspectorDestination() {
		if !router.inspectorPath.isEmpty {
			router.inspectorPath.removeLast()
		} else {
			dismissInspector()
		}
	}

	private func dismissInspector() {
		router.inspectorRoute = nil
		router.inspectorPath = []
	}

	private func closeDetailDestination() {
		guard !router.sidebarPath.isEmpty else {
			return
		}

		router.sidebarPath.removeLast()
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
					dismissInspector()
				}
			}
		)
	}

	private func sidebarRoot(
		_ title: String,
		systemImage: String,
		destination: AppRootDestination
	) -> some View {
		Button(action: { router.selectRoot(destination) }) {
			Label(title, systemImage: systemImage)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.horizontal, 10)
				.padding(.vertical, 7)
		}
		.buttonStyle(.plain)
		.foregroundStyle(router.selectedSidebarDestination == destination ? Color.accentColor : Color.primary)
		.background {
			if router.selectedSidebarDestination == destination {
				RoundedRectangle(cornerRadius: 8)
					.fill(Color.accentColor.opacity(0.15))
			}
		}
		.clipShape(RoundedRectangle(cornerRadius: 8))
		.contentShape(Rectangle())
	}
}
