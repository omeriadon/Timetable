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

	var sidebarVisibility: AppSidebarVisibility

	var inspectorRoute: AppRoute? {
		didSet {
			if inspectorRoute == nil {
				inspectorPath = []
			}
		}
	}

	var inspectorPath: [AppRoute]
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
	@ObservationIgnored
	private var isTranslatingPresentation = false

	init(
		persistenceStore: AppNavigationPersistenceStore? = nil
	) {
		let persistenceStore = persistenceStore ?? AppNavigationPersistenceStore()
		let persistsNavigationState = Defaults[.persistsNavigationState]
		let snapshot = persistsNavigationState ? persistenceStore.load() : nil

		self.persistenceStore = persistenceStore
		selectedTab = snapshot?.selectedTab ?? .timetable
		timetablePath = snapshot?.timetablePath ?? []
		friendsPath = snapshot?.friendsPath ?? []
		settingsPath = snapshot?.settingsPath ?? []
		administrationPath = snapshot?.administrationPath ?? []
		selectedSidebarDestination = snapshot?.selectedSidebarDestination ?? .timetable
		sidebarPath = snapshot?.sidebarPath ?? []
		sidebarVisibility = .automatic
		inspectorRoute = nil
		inspectorPath = []
		pendingExternalRoute = nil
		presentation = .iOS
		self.persistsNavigationState = persistsNavigationState
	}

	func updatePresentation(_ presentation: AppPresentation) {
		guard self.presentation != presentation else {
			return
		}
		isTranslatingPresentation = true
		self.presentation = presentation
		translateCurrentRoute(to: presentation)
		isTranslatingPresentation = false
	}

	func selectRoot(_ destination: AppRootDestination) {
		selectedTab = destination
		selectedSidebarDestination = destination
		sidebarPath = []
		inspectorRoute = nil
		inspectorPath = []
	}

	func navigate(to route: AppRoute) {
		let destination = route.rootDestination
		selectedTab = destination
		selectedSidebarDestination = destination

		if case .root = route {
			selectRoot(destination)
			return
		}

		if case .timetable = route {
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
						inspectorPath = []
					case .inspector:
						showInspector(route)
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
		inspectorPath = []
		pendingExternalRoute = nil
		persistenceStore.clear()
	}

	func popCurrentRoute() {
		switch selectedTab {
			case .timetable:
				if !timetablePath.isEmpty {
					timetablePath.removeLast()
				}
			case .friends:
				if !friendsPath.isEmpty {
					friendsPath.removeLast()
				}
			case .settings:
				if !settingsPath.isEmpty {
					settingsPath.removeLast()
				}
			case .administration:
				if !administrationPath.isEmpty {
					administrationPath.removeLast()
				}
		}
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
					for route in inspectorPath {
						append(route, to: inspectorRoute.rootDestination)
					}
					self.inspectorRoute = nil
					inspectorPath = []
					sidebarPath = []
				} else if !sidebarPath.isEmpty {
					for route in sidebarPath {
						append(route, to: route.rootDestination)
					}
					sidebarPath = []
				}
			case .iPadOS, .macOS:
				let compactPath = path(for: selectedTab)
				guard !compactPath.isEmpty else {
					return
				}

				if let inspectorIndex = compactPath.firstIndex(where: {
					AppRoutePresentationPolicy(route: $0) == .inspector
				}) {
					sidebarPath = Array(compactPath[..<inspectorIndex])
					inspectorRoute = compactPath[inspectorIndex]
					inspectorPath = Array(compactPath.dropFirst(inspectorIndex + 1))
				} else {
					sidebarPath = compactPath
					inspectorRoute = nil
					inspectorPath = []
				}
				clearPath(for: selectedTab)
		}
	}

	private func showInspector(_ route: AppRoute) {
		if inspectorRoute == nil {
			inspectorRoute = route
			inspectorPath = []
		} else {
			inspectorPath.append(route)
		}
	}

	private func clearPath(for destination: AppRootDestination) {
		switch destination {
			case .timetable:
				timetablePath = []
			case .friends:
				friendsPath = []
			case .settings:
				settingsPath = []
			case .administration:
				administrationPath = []
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
		guard persistsNavigationState, !isTranslatingPresentation else {
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
			sidebarPath: sidebarPath
		)
	}
}
