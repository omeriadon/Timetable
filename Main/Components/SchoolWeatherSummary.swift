import SwiftUI

struct SchoolWeatherSummary: View {
	let weather: SchoolWeather
	let font: Font
	let foregroundStyle: Color
	let maximumSpacerWidth: CGFloat

	init(
		weather: SchoolWeather,
		font: Font = .callout,
		foregroundStyle: Color = .secondary,
		maximumSpacerWidth: CGFloat = 15
	) {
		self.weather = weather
		self.font = font
		self.foregroundStyle = foregroundStyle
		self.maximumSpacerWidth = maximumSpacerWidth
	}

	var body: some View {
		HStack {
			Label {
				Text("\(weather.temperatureCelsius.formatted(.number.precision(.fractionLength(0))))°C")
			} icon: {
				Image(systemName: "thermometer.medium")
			}

			Spacer(minLength: 1)
				.frame(maxWidth: maximumSpacerWidth)

			Label(conditionTitle, systemImage: "cloud.sun")

			Spacer(minLength: 1)
				.frame(maxWidth: maximumSpacerWidth)

			Label {
				Text(
					weather.precipitationChance,
					format: .percent.precision(.fractionLength(0))
				)
			} icon: {
				Image(systemName: "drop")
			}

			Spacer(minLength: 1)
				.frame(maxWidth: maximumSpacerWidth)

			Label("UV \(weather.uvIndex)", systemImage: "sun.max")
		}
		.font(font)
		.frame(maxWidth: .infinity, alignment: .leading)
		.foregroundStyle(foregroundStyle)
		.accessibilityElement(children: .combine)
		.accessibilityLabel(
			"School weather, \(weather.temperatureCelsius.formatted(.number.precision(.fractionLength(0)))) degrees Celsius, \(conditionTitle), \(weather.precipitationChance.formatted(.percent.precision(.fractionLength(0)))) chance of precipitation, UV index \(weather.uvIndex)"
		)
	}

	private var conditionTitle: String {
		weather.conditionCode
			.replacingOccurrences(
				of: "([a-z])([A-Z])",
				with: "$1 $2",
				options: .regularExpression
			)
	}
}
