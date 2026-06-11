//
//  Timetable_WatchApp.swift
//  Timetable Watch Watch App
//
//  Created by Adon Omeri on 26/4/2026.
//

import Defaults
import SwiftUI

@main
struct Timetable_Watch_Watch_AppApp: App {
	@Default(.receivedTimetables) var receivedTimetables

	var body: some Scene {
		WindowGroup {
			TabView {
				Tab("Timetable", systemImage: "calendar") {
					ContentView()
				}

				Tab("Current Class", systemImage: "timer") {
					CurrentClassView()
				}

				ForEach(receivedTimetables) { receivedTimetable in
					Tab(receivedTimetable.sender, systemImage: "person") {
						FriendsTimetables(receivedTimetable: receivedTimetable)
					}
				}
			}
			.monospaced()
			.tabViewStyle(.verticalPage)
		}
	}
}
