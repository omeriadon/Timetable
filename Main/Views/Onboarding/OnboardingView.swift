//
//  OnboardingView.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import ColorfulX
import Defaults
import EventKit
import SwiftUI
import UserNotifications

struct OnboardingView: View {
	@Default(.hasCompletedOnboarding) private var hasCompletedOnboarding
	@State private var context = OnboardingPageContext()
	@State private var pages: [OnboardingPage] = []
	@State private var selectedID = ""
	@State private var displayedBackgroundID = ""
	@State private var backgroundBlur: CGFloat = 0
	@State private var backgroundOpacity = 1.0
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	var body: some View {
		GeometryReader { geometry in
			ZStack {
				background
				ScrollViewReader { proxy in
					ScrollView(.horizontal) {
						LazyHStack(spacing: 0) {
							ForEach(pages) { page in
								pageView(page)
									.frame(width: geometry.size.width, height: geometry.size.height)
									.id(page.id)
							}
						}
					}
					.scrollIndicators(.hidden)
					.scrollDisabled(true)
					.onChange(of: selectedID) { oldID, newID in
						guard !oldID.isEmpty, oldID != newID else { return }
						withAnimation(reduceMotion ? .none : .smooth(duration: 0.65)) {
							proxy.scrollTo(newID, anchor: .center)
						}
						animateBackground(to: newID)
					}
				}
			}
		}
		.safeAreaInset(edge: .bottom, alignment: .center, spacing: 0) {
			controls
				.ignoresSafeArea()
		}
		.task { await buildPages() }
	}

	private var background: some View {
		ZStack {
			if let page = pages.first(where: { $0.id == displayedBackgroundID }) {
				page.background()
					.id(page.id)
					.transition(.opacity)
			}
		}
		.padding(40)
		.blur(radius: reduceMotion ? 0 : backgroundBlur)
		.padding(-40)
		.opacity(backgroundOpacity)
		.ignoresSafeArea()
	}

	private func pageView(_ page: OnboardingPage) -> some View {
		VStack(spacing: 24) {
			Text(page.title)
				.font(.largeTitle.bold())
				.multilineTextAlignment(.center)
			page.content()
				.frame(maxWidth: 620, maxHeight: .infinity)
			if page.id == selectedID, let message = context.statusMessage {
				Text(message)
					.contentTransition(.numericText())
					.font(.callout)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
					.padding(.bottom, 20)
					.transition(.blurReplace)
			}
		}
		.animation(.easeInOut, value: context.statusMessage)
		.padding(.horizontal, 24)
		.padding(.top, 24)
		.environment(\.onboardingPageContext, context)
	}

	private var controls: some View {
		HStack(spacing: 12) {
			Button {
				move(by: -1)
			} label: {
				HStack {
					Image(systemName: "chevron.left")

					Text("Back")
				}
			}
			.font(.title3)
			.buttonStyle(.glassProminent)
			.controlSize(.extraLarge)
			.disabled(selectedIndex == 0 || context.isWorking)

			Spacer()

			Text("\(min(selectedIndex + 1, pages.count)) of \(pages.count)")
				.contentTransition(.numericText())

			Spacer()

			Button {
				if selectedIndex == pages.count - 1 {
					hasCompletedOnboarding = true
				} else {
					move(by: 1)
				}
			} label: {
				HStack {
					Text(selectedIndex == pages.count - 1 ? "Finish" : "Next")
						.contentTransition(.numericText())
					Image(systemName: "chevron.right")
				}
				.animation(.easeInOut, value: selectedIndex)
			}
			.font(.title3)
			.buttonStyle(.glassProminent)
			.controlSize(.extraLarge)
			.disabled(!context.canAdvance || context.isWorking || pages.isEmpty)
		}
		.padding(.horizontal, 20)
	}

	private var selectedIndex: Int {
		pages.firstIndex(where: { $0.id == selectedID }) ?? 0
	}

	private func move(by offset: Int) {
		let destination = selectedIndex + offset
		guard pages.indices.contains(destination) else { return }
		context.configure(canAdvance: false)
		selectedID = pages[destination].id
	}

	private func animateBackground(to newID: String) {
		if reduceMotion {
			withAnimation(.easeInOut(duration: 0.25)) {
				displayedBackgroundID = newID
			}
			return
		}

		Task { @MainActor in
			withAnimation(.easeIn(duration: 0.18)) {
				backgroundBlur = 8
				backgroundOpacity = 0.35
			}
			try? await Task.sleep(for: .seconds(0.18))
			displayedBackgroundID = newID
			withAnimation(.easeOut(duration: 0.24)) {
				backgroundBlur = 0
				backgroundOpacity = 1
			}
		}
	}

	private func buildPages(preserving currentID: String? = nil) async {
		let calendarGranted = EKEventStore.authorizationStatus(for: .event) == .fullAccess
		let notificationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
		let notificationGranted = [.authorized, .provisional, .ephemeral].contains(notificationStatus)

		let candidates = makePages(calendarGranted: calendarGranted, notificationGranted: notificationGranted)
		pages = candidates.filter { $0.isVisible() }
		let retainedID = currentID.flatMap { id in pages.contains(where: { $0.id == id }) ? id : nil }
		selectedID = retainedID ?? pages.first?.id ?? ""
		displayedBackgroundID = selectedID
	}

	private func makePages(calendarGranted: Bool, notificationGranted: Bool) -> [OnboardingPage] {
		[
			OnboardingPage(id: "splash", title: "") {
				SplashView()
			} background: {
				SplashGradient()
					.onAppear { context.configure(canAdvance: true) }

			},
			OnboardingPage(id: "calendar", title: "Calendar Access", isVisible: { !calendarGranted }) {
				OnboardingCalendarPermissionView()
			} background: {
				CalendarGradient()
			},
			OnboardingPage(id: "calendar-import", title: "Import Your Timetable") {
				OnboardingCalendarImportView()
			} background: {
				Color.blue
			},
			OnboardingPage(id: "welcome", title: "Welcome to Timetable") {
				Text("")
					.onAppear { context.configure(canAdvance: true) }

//				OnboardingSimplePage(
//					systemImage: "calendar.day.timeline.left",
//					text: "Keep your timetable, school-day alerts, and Live Activities together across your devices."
//				)
			} background: {
				Color.blue
			},
			OnboardingPage(id: "notifications", title: "Stay Up to Date", isVisible: { !notificationGranted }) {
				OnboardingNotificationPermissionView()
			} background: {
				NotifGradient()
			},
			OnboardingPage(id: "apns", title: "Register This Device") {
				OnboardingAPNsRegistrationView()
			} background: {
				Color.blue
			},
			OnboardingPage(id: "account", title: "Your Account") {
				OnboardingAccountView()
			} background: {
				Color.blue
			},
			OnboardingPage(id: "finished", title: "Ready to Begin") {
//				OnboardingSimplePage(systemImage: "checkmark.circle.fill", text: "Timetable is configured for this device.")
				Text("")
					.onAppear { context.configure(canAdvance: true) }

			} background: {
				Color.blue
			},
		]
	}
}
