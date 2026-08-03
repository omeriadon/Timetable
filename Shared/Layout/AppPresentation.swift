#if !os(watchOS)
	import SwiftUI

	enum AppPresentation: String, Codable, Hashable, Sendable {
		case iOS
		case iPadOS
		case macOS

		func value<Value>(
			iOS: Value,
			macOS: Value
		) -> Value {
			switch self {
				case .iOS, .iPadOS:
					iOS
				case .macOS:
					macOS
			}
		}

		func value<Value>(
			iOS: Value,
			iPadOS: Value,
			macOS: Value
		) -> Value {
			switch self {
				case .iOS:
					iOS
				case .iPadOS:
					iPadOS
				case .macOS:
					macOS
			}
		}

		static func resolve(
			horizontalSizeClass: UserInterfaceSizeClass?,
			presentationWidth: CGFloat
		) -> AppPresentation {
			#if os(macOS)
				.macOS
			#elseif os(iOS)
				if horizontalSizeClass == .regular || presentationWidth >= 600 {
					.iPadOS
				} else {
					.iOS
				}
			#else
				.iOS
			#endif
		}
	}

	private struct AppPresentationKey: EnvironmentKey {
		#if os(macOS)
			static let defaultValue = AppPresentation.macOS
		#else
			static let defaultValue = AppPresentation.iOS
		#endif
	}

	extension EnvironmentValues {
		var appPresentation: AppPresentation {
			get { self[AppPresentationKey.self] }
			set { self[AppPresentationKey.self] = newValue }
		}
	}

#endif
