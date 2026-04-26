//
//  ContentView.swift
//  PMS Timetable Watch Watch App
//
//  Created by Adon Omeri on 26/4/2026.
//

import SwiftUI

struct ContentView: View {
@State private var classes: [Class] = []
@State private var selectedDay = 0
@State private var isLoading = false
@State private var syncError: String?
@State private var showSyncError = false

let sessions = ["1", "2", "R", "3", "4", "L", "5", "6"]
let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri"]

var body: some View {
NavigationStack {
VStack(spacing: 8) {
// Day selector TabView (horizontal)
TabView(selection: $selectedDay) {
ForEach(0..<5, id: \.self) { day in
dayView(day)
.tag(day)
}
}
.tabViewStyle(.page(indexDisplayMode: .never))
.frame(maxWidth: .infinity, maxHeight: .infinity)

// Day indicator
HStack(spacing: 4) {
ForEach(0..<5, id: \.self) { day in
Text(dayLabels[day])
.font(.system(size: 9, weight: .semibold, design: .monospaced))
.foregroundStyle(day == selectedDay ? .white : .gray)
.frame(maxWidth: .infinity)
}
}
.padding(.horizontal, 4)
.padding(.bottom, 4)
}
.toolbar {
ToolbarItem(placement: .topBarLeading) {
Button {
Task { await loadTimetableAsync() }
} label: {
if isLoading {
ProgressView()
.scaleEffect(0.7)
} else {
Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
.font(.system(size: 10, weight: .semibold, design: .monospaced))
}
}
.disabled(isLoading)
}
}
.navigationBarTitleDisplayMode(.inline)
}
.environment(\.dynamicTypeSize, .xSmall)
.monospaced()
.onAppear {
print("[Watch] ContentView appeared, loading timetable...")
Task { await loadTimetableAsync() }
}
.alert(
"Sync Error",
isPresented: $showSyncError,
actions: {
Button("OK", role: .cancel) {
syncError = nil
showSyncError = false
}
},
message: {
Text(syncError ?? "Unknown error")
}
)
}

@ViewBuilder
func dayView(_ day: Int) -> some View {
ScrollView(.vertical, showsIndicators: false) {
VStack(spacing: 4) {
ForEach(0..<8, id: \.self) { session in
sessionCell(day, session)
}
}
.padding(.horizontal, 4)
.padding(.vertical, 6)
}
}

@ViewBuilder
func sessionCell(_ day: Int, _ session: Int) -> some View {
if session == 2 || session == 5 {
HStack {
Text(sessions[session])
.font(.system(size: 8, weight: .semibold, design: .monospaced))
.foregroundStyle(.secondary)
.frame(width: 12)
Spacer()
}
.frame(height: 8)
} else {
if day == 2 && session == 7 || day == 4 && session == 7 {
HStack {
Text(sessions[session])
.font(.system(size: 8, weight: .semibold, design: .monospaced))
.foregroundStyle(.tertiary)
.frame(width: 12)
Spacer()
}
.frame(height: 12)
} else {
if let c = classFor(day: day, session: session) {
HStack(spacing: 3) {
Image(systemName: c.symbol)
.font(.system(size: 9, weight: .semibold))
.foregroundStyle(.white)
.frame(width: 14)

VStack(alignment: .leading, spacing: 1) {
Text(c.id)
.font(.system(size: 8, weight: .semibold, design: .monospaced))
.lineLimit(1)
Text(sessions[session])
.font(.system(size: 7, weight: .regular, design: .monospaced))
.foregroundStyle(.secondary)
.lineLimit(1)
}
.frame(maxWidth: .infinity, alignment: .leading)
}
.padding(.horizontal, 3)
.padding(.vertical, 2)
.background(c.colour.swiftUIColor.opacity(0.8), in: RoundedRectangle(cornerRadius: 4))
.frame(height: 18)
} else {
HStack {
Text(sessions[session])
.font(.system(size: 8, weight: .semibold, design: .monospaced))
.foregroundStyle(.tertiary)
.frame(width: 12)
Spacer()
}
.frame(height: 12)
}
}
}
}

func classFor(day: Int, session: Int) -> Class? {
classes.first { c in
c.slots.contains {
$0.day == day && $0.session == session
}
}
}

func loadTimetableAsync() async {
isLoading = true
print("[Watch] Starting sync (isLoading = true)...")
defer {
print("[Watch] Sync completed, isLoading = false")
isLoading = false
}

do {
print("[Watch] Reading from shared container (App Groups)...")
let sharedDefaults = UserDefaults(suiteName: "group.com.omeriadon.pms-timetable")
		print("[Watch] Shared container: \(sharedDefaults != nil ? "✓ found" : "✗ NOT found")")
		guard let data = sharedDefaults?.data(forKey: "watchTimetable") else {
print("[Watch] No data found in UserDefaults")
syncError = "No timetable synced from iOS yet. Tap sync on iOS app first."
showSyncError = true
return
}

print("[Watch] Data found: \\(data.count) bytes")
print("[Watch] Decoding JSON...")
let decoded = try JSONDecoder().decode([Class].self, from: data)
print("[Watch] Decoded \\(decoded.count) classes")

print("[Watch] Updating UI state...")
await MainActor.run {
self.classes = decoded
print("[Watch] ✓ UI updated with \\(self.classes.count) classes")
}
} catch {
print("[Watch] ✗ Sync failed: \\(error)")
syncError = "Decode failed: \\(error.localizedDescription)"
showSyncError = true
}
}
}

// MARK: - Models

struct Class: Hashable, Codable, Identifiable {
var id: String
var symbol: String
var colour: RGBAColor
var slots: [Slot]
}

struct Slot: Hashable, Codable {
let day: Int
let session: Int

init(_ day: Int, _ session: Int) {
self.day = day
self.session = session
}
}

struct RGBAColor: Codable, Hashable {
var r: Double
var g: Double
var b: Double
var a: Double

var swiftUIColor: Color {
Color(red: r, green: g, blue: b, opacity: a)
}
}

#Preview {
ContentView()
}
