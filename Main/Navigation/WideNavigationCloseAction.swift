import SwiftUI

private struct WideNavigationCloseActionKey: EnvironmentKey {
	static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
	var closeWideNavigationDestination: () -> Void {
		get { self[WideNavigationCloseActionKey.self] }
		set { self[WideNavigationCloseActionKey.self] = newValue }
	}
}
