import Defaults
import SwiftUI

struct NonAuthoritativeSettingsView: View {
	@Binding var expanded: WindowMode

	init(expanded: Binding<WindowMode>) {
		_expanded = expanded
	}

	var body: some View {
		NavigationStack {
			Form {
				Section("Account") {
					NavigationLink {
						NonAuthoritativeAccountView()
					} label: {
						Label("Account", systemImage: "person.crop.circle")
					}
				}

				Section("Preferences") {
					NavigationLink {
						NotificationPreferencesView()
					} label: {
						Label("Notifications", systemImage: "bell")
					}

					Toggle("Highlight Current Day in timetables", isOn: Binding(
						get: { Defaults[.timetableHighlightsCurrentDay] },
						set: { Defaults[.timetableHighlightsCurrentDay] = $0 }
					))
				}

				Section {
					Button("Sign Out", role: .destructive) {
						Task {
							await SessionStore.shared.signOut()
						}
					}
					.foregroundStyle(.red)
				}
			}
			.scrollContentBackground(.hidden)
			.formStyle(.grouped)
			.appNavigationTitle("Settings", style: .main)
		}
		#if os(macOS)
		.onAppear { expanded = .settings }
		.onDisappear { expanded = .none }
		#endif
	}
}
