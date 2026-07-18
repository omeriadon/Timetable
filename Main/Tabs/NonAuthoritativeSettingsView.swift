import Defaults
import SwiftUI

struct NonAuthoritativeSettingsView: View {
	var body: some View {
		NavigationStack {
			Form {
				Section("Account") { NavigationLink { NonAuthoritativeAccountView() } label: { Label("Account", systemImage: "person.crop.circle") } }
				Section("Preferences") {
					NavigationLink { NotificationPreferencesView() } label: { Label("Notifications", systemImage: "bell") }
					Toggle("Highlight Current Day in timetables", isOn: Binding(
						get: { Defaults[.timetableHighlightsCurrentDay] },
						set: { Defaults[.timetableHighlightsCurrentDay] = $0 }
					))
				}
				Section { Button("Sign Out", role: .destructive) { Task { await SessionStore.shared.signOut() } } }
			}
			.formStyle(.grouped)
			.appNavigationTitle("Settings", style: .main)
		}
	}
}
