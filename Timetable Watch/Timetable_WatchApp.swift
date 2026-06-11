//
//  Timetable_WatchApp.swift
//  Timetable Watch Watch App
//
//  Created by Adon Omeri on 26/4/2026.
//

import SwiftUI

@main
struct Timetable_Watch_Watch_AppApp: App {
	var body: some Scene {
		WindowGroup {
			TabView {
				Tab("Timetable", systemImage: "calendar") {
					ContentView()
				}

				Tab("Current Class", systemImage: "timer") {
					CurrentClassView()
				}
			}
			.monospaced()
			.tabViewStyle(.verticalPage)
		}
	}
}
