import Defaults
import Foundation
import Observation

@MainActor
@Observable
final class AppRouter {
	var selectedTab: MainTab {
		didSet { persistIfNeeded() }
	}

	var timetablePath: [AppRoute] {
		didSet { persistIfNeeded() }
	}

	var friendsPath: [AppRoute] {
		didSet { persistIfNeeded() }
	}

	var settingsPath: [AppRoute] {
		didSet { persistIfNeeded() }
	}

	var administrationPath: [AppRoute] {
		didSet { persistIfNeeded() }
	}

	var selectedSidebarDestination: AppRootDestination {
		didSet { persistIfNeeded() }
	}

	var sidebarPath: [AppRoute] {
		didSet { persistIfNeeded() }
	}

	var sidebarVisibility: AppSidebarVisibility {
		didSet { persistIfNeeded() }
	}

	var inspectorRoute: AppRoute?
	var pendingExternalRoute: AppRoute?
	var presentation: AppPresentation

	var persistsNavigationState: Bool {
		didSet {
			Defaults[.persistsNavigationState] = persistsNavigationState
			if persistsNavigationState {
				persistIfNeeded()
			} else {
				persistenceStore.clear()
			}
		}
	}

	@ObservationIgnored
	private let persistenceStore: AppNavigationPersistenceStore

	init(
		persistenceStore: AppNavigationPersistenceStore = AppNavigationPersistenceStore()
	) {
		self.persistenceStore = persistenceStore
		persistsNavigationState = Defaults[.persistsNavigationState]

		let snapshot = persistsNavigationState ? persistenceStore.load() : nil
		selectedTab = snapshot?.selectedTab ?? .timetable
		timetablePath = snapshot?.timetablePath ?? []
		friendsPath = snapshot?.friendsPath ?? []
		settingsPath = snapshot?.settingsPath ?? []
		administrationPath = snapshot?.administrationPath ?? []
		selectedSidebarDestination = snapshot?.selectedSidebarDestination ?? .timetable
		sidebarPath = snapshot?.sidebarPath ?? []
		sidebarVisibility = snapshot?.sidebarVisibility ?? .automatic
		inspectorRoute = nil
		pendingExternalRoute = nil
		presentation = .iOS
	}

	func updatePresentation(_ presentation: AppPresentation) {
		guard self.presentation != presentation else {
			return
		}
		self.presentation = presentation
		translateCurrentRoute(to: presentation)
	}

	func selectRoot(_ destination: AppRootDestination) {
		selectedTab = destination
		selectedSidebarDestination = destination
		sidebarPath = []
		inspectorRoute = nil
	}

	func navigate(to route: AppRoute) {
		let destination = route.rootDestination
		selectedTab = destination
		selectedSidebarDestination = destination

		if case .root = route {
			selectRoot(destination)
			return
		}

		switch presentation {
			case .iOS:
				append(route, to: destination)
			case .iPadOS, .macOS:
				switch AppRoutePresentationPolicy(route: route) {
					case .detail:
						sidebarPath.append(route)
						inspectorRoute = nil
					case .inspector:
						inspectorRoute = route
				}
		}
	}

	func deferExternalRoute(_ route: AppRoute) {
		pendingExternalRoute = route
	}

	@discardableResult
	func resumePendingExternalRoute() -> AppRoute? {
		guard let route = pendingExternalRoute else {
			return nil
		}
		pendingExternalRoute = nil
		navigate(to: route)
		return route
	}

	func clearNavigation() {
		selectedTab = .timetable
		timetablePath = []
		friendsPath = []
		settingsPath = []
		administrationPath = []
		selectedSidebarDestination = .timetable
		sidebarPath = []
		sidebarVisibility = .automatic
		inspectorRoute = nil
		pendingExternalRoute = nil
		persistenceStore.clear()
	}

	private func append(
		_ route: AppRoute,
		to destination: AppRootDestination
	) {
		switch destination {
			case .timetable:
				timetablePath.append(route)
			case .friends:
				friendsPath.append(route)
			case .settings:
				settingsPath.append(route)
			case .administration:
				administrationPath.append(route)
		}
	}

	private func translateCurrentRoute(to presentation: AppPresentation) {
		switch presentation {
			case .iOS:
				if let inspectorRoute {
					append(inspectorRoute, to: inspectorRoute.rootDestination)
					self.inspectorRoute = nil
				} else if let route = sidebarPath.last {
					append(route, to: route.rootDestination)
				}
			case .iPadOS, .macOS:
				let compactPath = path(for: selectedTab)
				guard let route = compactPath.last else {
					return
				}
				switch AppRoutePresentationPolicy(route: route) {
					case .detail:
						sidebarPath = [route]
					case .inspector:
						inspectorRoute = route
				}
		}
	}

	private func path(for destination: AppRootDestination) -> [AppRoute] {
		switch destination {
			case .timetable:
				timetablePath
			case .friends:
				friendsPath
			case .settings:
				settingsPath
			case .administration:
				administrationPath
		}
	}

	private func persistIfNeeded() {
		guard persistsNavigationState else {
			return
		}
		persistenceStore.save(snapshot)
	}

	private var snapshot: AppNavigationSnapshot {
		AppNavigationSnapshot(
			selectedTab: selectedTab,
			timetablePath: timetablePath,
			friendsPath: friendsPath,
			settingsPath: settingsPath,
			administrationPath: administrationPath,
			selectedSidebarDestination: selectedSidebarDestination,
			sidebarPath: sidebarPath,
			sidebarVisibility: sidebarVisibility
		)
	}
}
