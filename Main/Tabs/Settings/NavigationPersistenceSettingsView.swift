import SwiftUI

struct NavigationPersistenceSettingsView: View {
	@Environment(AppRouter.self) private var router

	var body: some View {
		@Bindable var router = router
		List {
			Section {
				Toggle(
					"Restore Navigation",
					systemImage: "arrow.counterclockwise.circle",
					isOn: $router.persistsNavigationState
				)
			} footer: {
				Text("Restore the selected tab, sidebar, and navigation path when reopening Timetable.")
			}
			.glurListRowBackground()
		}
		.appPaperBackground()
		.appNavigationTitle("Navigation", accent: true)
	}
}
