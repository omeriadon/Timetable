import Charts
import SwiftUI

struct AdministrationDeviceStatisticsView: View {
	@State private var model = AdministrationStatisticsModel()
	@State private var operatingSystemChartMode = OperatingSystemChartMode.majorVersions
	@Environment(\.statusBadgeManager) private var statusBadges

	var body: some View {
		List {
			Section("Builds") {
				if let statistics = model.statistics {
					LabeledContent("Debug builds", value: statistics.debugDevices.formatted())
					LabeledContent("Beta builds", value: statistics.betaDevices.formatted())
					LabeledContent("Release builds", value: statistics.releaseDevices.formatted())
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
				Picker("View", selection: $operatingSystemChartMode) {
					Text("Major versions")
						.tag(OperatingSystemChartMode.majorVersions)

					Text("Builds")
						.tag(OperatingSystemChartMode.builds)

					Text("Minor versions")
						.tag(OperatingSystemChartMode.minorVersions)

					Divider()

					ForEach(availableMajorVersions, id: \.self) { majorVersion in
						Text("Minor versions for OS \(majorVersion)")
							.tag(OperatingSystemChartMode.minorVersionsForMajor(majorVersion))
					}
				}
				.pickerStyle(.menu)

				if !operatingSystemChartItems.isEmpty {
					Chart(operatingSystemChartItems) { item in
						SectorMark(angle: .value("Devices", item.count))
							.foregroundStyle(by: .value("Operating system", item.chartLabel))
					}
					.frame(height: 220)

					ForEach(operatingSystemChartItems) { item in
						HStack {
							Text(item.label)
							Spacer()
							if item.isDebug {
								Image(systemName: "flask")
									.foregroundStyle(.secondary)
									.accessibilityLabel("Debug build")
							}
							if let buildLabel = item.buildLabel {
								Text(buildLabel)
									.foregroundStyle(.secondary)
							}
							Text(item.count.formatted())
								.foregroundStyle(.secondary)
						}
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
							HStack {
								Text("OS \(item.osMajorVersion).\(item.osMinorVersion)")
								Spacer()
								if item.isDebug {
									Image(systemName: "flask")
										.foregroundStyle(.secondary)
										.accessibilityLabel("Debug build")
								}
								Text(item.buildLabel)
									.foregroundStyle(.secondary)
								Text(item.count.formatted())
									.foregroundStyle(.secondary)
							}
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

	private var availableMajorVersions: [Int] {
		Set((model.statistics?.deviceOSVersions ?? []).map(\.osMajorVersion))
			.sorted(by: >)
	}

	private var operatingSystemChartItems: [OperatingSystemChartItem] {
		guard let statistics = model.statistics else { return [] }

		switch operatingSystemChartMode {
			case .majorVersions:
				return groupedMajorVersions(statistics.deviceOSVersions)
			case .builds:
				return [
					OperatingSystemChartItem(label: "Debug", chartLabel: "Debug", count: statistics.debugDevices),
					OperatingSystemChartItem(label: "Beta", chartLabel: "Beta", count: statistics.betaDevices),
					OperatingSystemChartItem(label: "Release", chartLabel: "Release", count: statistics.releaseDevices),
				].filter { $0.count > 0 }
			case .minorVersions:
				return groupedMinorVersions(statistics.deviceOSVersions)
			case let .minorVersionsForMajor(majorVersion):
				return groupedMinorVersions(
					statistics.deviceOSVersions.filter { $0.osMajorVersion == majorVersion }
				)
		}
	}

	private func groupedMajorVersions(_ versions: [AdministrationDeviceOSVersionCount]) -> [OperatingSystemChartItem] {
		let grouped = Dictionary(grouping: versions, by: \.osMajorVersion)
		return grouped.map { majorVersion, entries in
			OperatingSystemChartItem(
				label: "OS \(majorVersion)",
				chartLabel: "OS \(majorVersion)",
				count: entries.reduce(0) { $0 + $1.count }
			)
		}.sorted { $0.label > $1.label }
	}

	private func groupedMinorVersions(_ versions: [AdministrationDeviceOSVersionCount]) -> [OperatingSystemChartItem] {
		versions.map {
			let label = "OS \($0.osMajorVersion).\($0.osMinorVersion)"
			return OperatingSystemChartItem(
				label: label,
				chartLabel: "\(label) · \($0.buildLabel)",
				count: $0.count,
				isDebug: $0.isDebug,
				buildLabel: $0.buildLabel
			)
		}.sorted {
			if $0.label == $1.label {
				return ($0.buildLabel ?? "") < ($1.buildLabel ?? "")
			}
			return $0.label > $1.label
		}
	}
}

private enum OperatingSystemChartMode: Hashable {
	case majorVersions
	case builds
	case minorVersions
	case minorVersionsForMajor(Int)
}

private struct OperatingSystemChartItem: Identifiable {
	let label: String
	let chartLabel: String
	let count: Int
	let isDebug: Bool
	let buildLabel: String?

	init(label: String, chartLabel: String, count: Int, isDebug: Bool = false, buildLabel: String? = nil) {
		self.label = label
		self.chartLabel = chartLabel
		self.count = count
		self.isDebug = isDebug
		self.buildLabel = buildLabel
	}

	var id: String {
		"\(chartLabel)-\(isDebug)"
	}
}

private extension AdministrationDeviceOSVersionCount {
	var buildLabel: String {
		if isDebug {
			return "Debug"
		}
		return isBeta ? "Beta" : "Release"
	}
}
