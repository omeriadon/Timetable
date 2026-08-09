import Charts
import SwiftUI

struct AdministrationDeviceStatisticsView: View {
	@State private var model = AdministrationStatisticsModel()
	@Environment(\.statusBadgeManager) private var statusBadges

	var body: some View {
		List {
			Section("Builds") {
				if let statistics = model.statistics {
					LabeledContent("Debug builds", value: statistics.debugDevices.formatted())
					LabeledContent("Beta builds", value: statistics.betaDevices.formatted())
				}
			}

			Section("Device types") {
				if let deviceTypes = model.statistics?.deviceTypes, !deviceTypes.isEmpty {
					Chart(deviceTypes) { item in
						SectorMark(angle: .value("Devices", item.count))
							.foregroundStyle(by: .value("Device type", item.label))
					}
					.frame(height: 220)

					ForEach(deviceTypes) { item in
						LabeledContent(item.label, value: item.count.formatted())
					}
				} else {
					Text("No device data")
						.foregroundStyle(.secondary)
				}
			}

			Section("Operating system versions") {
				if let osVersions = model.statistics?.osVersions, !osVersions.isEmpty {
					Chart(osVersions) { item in
						SectorMark(angle: .value("Devices", item.count))
							.foregroundStyle(by: .value("Operating system", item.label))
					}
					.frame(height: 220)

					ForEach(osVersions) { item in
						LabeledContent(item.label, value: item.count.formatted())
					}
				} else {
					Text("No operating system data")
						.foregroundStyle(.secondary)
				}
			}

			Section("Operating systems by device type") {
				let grouped = Dictionary(grouping: model.statistics?.deviceOSVersions ?? [], by: \.platform)
				ForEach(grouped.keys.sorted(), id: \.self) { platform in
					DisclosureGroup(platform) {
						ForEach(grouped[platform] ?? []) { item in
							LabeledContent(
								"OS \(item.osMajorVersion).\(item.osMinorVersion)",
								value: item.count.formatted()
							)
						}
					}
				}
				if grouped.isEmpty {
					Text("No per-device operating system data")
						.foregroundStyle(.secondary)
				}
			}
		}
		.scrollEdgeEffect()
		.appNavigationTitle("Devices", accent: true)
		.refreshable {
			await load()
		}
		.task {
			await load()
		}
	}

	private func load() async {
		if let error = await model.load(), !Task.isCancelled, !error.isCancellation {
			statusBadges.present(error: error, title: "Unable to load device statistics")
		}
	}
}
