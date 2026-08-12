import Charts
import SwiftUI

struct AdministrationDeviceStatisticsView: View {
	@State private var model = AdministrationStatisticsModel()
	@State private var operatingSystemChartMode = OperatingSystemChartMode.majorVersions
	@Environment(\.statusBadgeManager) private var statusBadges

	var body: some View {
		List {
			Section("App channels") {
				if let statistics = model.statistics {
					LabeledContent("Debug", value: statistics.debugDevices.formatted())
					LabeledContent("TestFlight", value: statistics.testFlightDevices.formatted())
					LabeledContent("App Store", value: statistics.releaseDevices.formatted())
				}
			}
			.glurListRowBackground()

			Section("App versions") {
				if let appVersions = model.statistics?.appVersions, !appVersions.isEmpty {
					Chart(appVersions) { item in
						SectorMark(angle: .value("Devices", item.count))
							.foregroundStyle(by: .value("App version", item.label))
							.accessibilityLabel("Version \(item.label)")
							.accessibilityValue("\(item.count) devices")
					}
					.frame(height: 220)

					ForEach(appVersions) { item in
						LabeledContent(item.label, value: item.count.formatted())
					}
				} else {
					Text("No app version data")
						.foregroundStyle(.secondary)
				}
			}
			.glurListRowBackground()

			Section("App versions and builds") {
				if let appVersionBuilds = model.statistics?.appVersionBuilds, !appVersionBuilds.isEmpty {
					Chart(appVersionBuilds) { item in
						SectorMark(angle: .value("Devices", item.count))
							.foregroundStyle(by: .value("App version and build", item.label))
							.accessibilityLabel(item.label)
							.accessibilityValue("\(item.count) devices")
					}
					.frame(height: 220)

					ForEach(appVersionBuilds) { item in
						LabeledContent(item.label, value: item.count.formatted())
					}
				} else {
					Text("No app build data")
						.foregroundStyle(.secondary)
				}
			}
			.glurListRowBackground()

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
			.glurListRowBackground()

			Section("Operating system versions") {
				Picker("View", selection: $operatingSystemChartMode) {
					Text("Major versions")
						.tag(OperatingSystemChartMode.majorVersions)

					Text("App channels")
						.tag(OperatingSystemChartMode.appChannels)

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
							if item.isOSBeta {
								Image(systemName: "flask")
									.foregroundStyle(.secondary)
									.accessibilityLabel("Beta operating system")
							}
							if item.isOSBeta {
								Text("Beta")
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
			.glurListRowBackground()

			Section("Operating systems by device type") {
				let grouped = Dictionary(grouping: model.statistics?.deviceOSVersions ?? [], by: \.platform)
				ForEach(grouped.keys.sorted(), id: \.self) { platform in
					DisclosureGroup(platform) {
						ForEach(grouped[platform] ?? []) { item in
							HStack {
								Text("OS \(item.osMajorVersion).\(item.osMinorVersion)")
								Spacer()
								if item.isOSBeta {
									Image(systemName: "flask")
										.foregroundStyle(.secondary)
										.accessibilityLabel("Beta operating system")
								}
								if item.isOSBeta {
									Text("Beta")
										.foregroundStyle(.secondary)
								}
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
			.glurListRowBackground()
		}
		.appPaperBackground()
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
			case .appChannels:
				return [
					OperatingSystemChartItem(label: "Debug", chartLabel: "Debug", count: statistics.debugDevices),
					OperatingSystemChartItem(label: "TestFlight", chartLabel: "TestFlight", count: statistics.testFlightDevices),
					OperatingSystemChartItem(label: "App Store", chartLabel: "App Store", count: statistics.releaseDevices),
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
				chartLabel: "\(label) · \($0.osBetaLabel)",
				count: $0.count,
				isOSBeta: $0.isOSBeta
			)
		}.sorted {
			if $0.label == $1.label {
				return !$0.isOSBeta && $1.isOSBeta
			}
			return $0.label > $1.label
		}
	}
}

private enum OperatingSystemChartMode: Hashable {
	case majorVersions
	case appChannels
	case minorVersions
	case minorVersionsForMajor(Int)
}

private struct OperatingSystemChartItem: Identifiable {
	let label: String
	let chartLabel: String
	let count: Int
	let isOSBeta: Bool

	init(label: String, chartLabel: String, count: Int, isOSBeta: Bool = false) {
		self.label = label
		self.chartLabel = chartLabel
		self.count = count
		self.isOSBeta = isOSBeta
	}

	var id: String {
		"\(chartLabel)-\(isOSBeta)"
	}
}

private extension AdministrationDeviceOSVersionCount {
	var osBetaLabel: String {
		isOSBeta ? "Beta" : "Release"
	}
}
