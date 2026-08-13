import SwiftUI

struct SchoolWeatherSummary: View {
	let weather: SchoolWeather
	let font: Font
	let foregroundStyle: Color

	init(
		weather: SchoolWeather,
		font: Font = .callout,
		foregroundStyle: Color = .secondary
	) {
		self.weather = weather
		self.font = font
		self.foregroundStyle = foregroundStyle
	}

	var body: some View {
		HStack {
			Label {
				Text("\(weather.temperatureCelsius.formatted(.number.precision(.fractionLength(0))))°C")
			} icon: {
				Image(systemName: "thermometer.medium")
			}

			Spacer(minLength: 1)
				.frame(maxWidth: 15)

			Label(conditionTitle, systemImage: "cloud.sun")

			Spacer(minLength: 1)
				.frame(maxWidth: 15)

			Label {
				Text(
					weather.precipitationChance,
					format: .percent.precision(.fractionLength(0))
				)
			} icon: {
				Image(systemName: "drop")
			}

			Spacer(minLength: 1)
				.frame(maxWidth: 15)

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
