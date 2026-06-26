//
//  CloudKit.swift
//  Timetable
//
//  Created by Adon Omeri on 12/6/2026.
//

import CloudKit
import Combine
import Defaults
import Foundation

@Observable
final class CloudStore {
	static let shared = CloudStore()

	private var cancellables = Set<AnyCancellable>()

	private let store = NSUbiquitousKeyValueStore.default

	private var isApplyingRemoteChange = false

	var accountStatus: CKAccountStatus = .couldNotDetermine

	private init() {
		NotificationCenter.default.publisher(
			for: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
			object: store
		)
		.sink { [weak self] _ in
			self?.pullEverything()
		}
		.store(in: &cancellables)

		store.synchronize()

		Defaults.publisher(.timetable)
			.sink { [weak self] _ in
				guard let self, !self.isApplyingRemoteChange else { return }
				pushEverything()
			}
			.store(in: &cancellables)

		Defaults.publisher(.userDisplayName)
			.sink { [weak self] _ in
				guard let self, !self.isApplyingRemoteChange else { return }
				pushEverything()
			}
			.store(in: &cancellables)
	}

	func pushEverything() {
		guard !isApplyingRemoteChange else { return }

		do {
			let data = try JSONEncoder().encode(Defaults[.timetable])
			store.set(data, forKey: "timetable")
		} catch {
			PrintError(error)
		}

		do {
			let data = try JSONEncoder().encode(Defaults[.userDisplayName])
			store.set(data, forKey: "userDisplayName")
		} catch {
			PrintError(error)
		}
	}

	func pullEverything() {
		isApplyingRemoteChange = true
		defer { isApplyingRemoteChange = false }

		if let data = store.data(forKey: "timetable"),
		   let timetable = try? JSONDecoder().decode(
		   	[Subject].self,
		   	from: data
		   )
		{
			Defaults[.timetable] = timetable
		}

		if let data = store.data(forKey: "userDisplayName"),
		   let userDisplayName = try? JSONDecoder().decode(
		   	String.self,
		   	from: data
		   )
		{
			Defaults[.userDisplayName] = userDisplayName
		}
	}

	func fetchAccountStatus() async {
		do {
			accountStatus = try await CKContainer.default().accountStatus()
		} catch {
			PrintError(error.localizedDescription)
		}
	}
}
