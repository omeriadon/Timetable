//
//  NetworkManager.swift
//  Timetable
//
//  Created by Adon Omeri on 14/5/2026.
//

import Foundation

final class NetworkManager {
	static let shared = NetworkManager()
	private init() {}

	func registerPushToStartToken(_ token: String) async {
		guard let url = URL(string: "https://t.adonis.pt/register/pushToken") else { return }

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		request.httpBody = try? JSONSerialization.data(withJSONObject: [
			"token": token,
		])

		_ = try? await URLSession.shared.data(for: request)
	}
}
