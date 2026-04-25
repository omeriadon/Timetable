//
//  ContentView.swift
//  PMS Timetable
//
//  Created by Adon Omeri on 25/4/2026.
//

import Defaults
import SwiftUI

struct ContentView: View {
	var body: some View {
		NavigationStack {
			VStack {
				HStack(spacing: 5) {
					VStack(spacing: 5) {
						Text("")

						ForEach(1..<9) { session in
							if session == 3 {
								Text("R")
							} else if session == 6 {
								Text("L")
							}
							else {
								Text("S\(session)")
									.frame(height: 60)
							}
						}
					}
					.frame(width: 25)

					ForEach(1..<6) { day in
						VStack(spacing: 5) {
							Text(["Mon", "Tue", "Wed", "Thu", "Fri"][day - 1])
							ForEach(1..<9) { session in
								if session == 3 || session == 6 {
									rectangle(.gray.opacity(0.5), true)
										.frame(height: 20)
								} else {
									rectangle(.blue)
										.frame(height: 60)
								}
							}
						}
					}
				}
				Spacer()
			}
			.padding(5)
			.toolbar {
				ToolbarItem(placement: .title) {
					Text("PMS Timetable")
						.monospaced()
				}

				ToolbarItem(placement: .topBarTrailing) {
					Button {} label: {
						Label("Sync", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
					}
					.buttonStyle(.glassProminent)
				}
			}
		}
		.environment(\.dynamicTypeSize, .xSmall)
		.monospaced()
	}
}

struct rectangle: View {
	let fill: Color

	let isBreak: Bool

	init(_ fill: Color, _ isBreak: Bool = false) {
		self.fill = fill
		self.isBreak = isBreak
	}

	var body: some View {
		RoundedRectangle(cornerRadius: isBreak ? 8 : 10)
			.fill(fill)
	}
}

#Preview {
	ContentView()
}
