//
//  OnboardingView.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import Defaults
import EventKit
import SwiftUI
import UserNotifications

struct OnboardingView: View {
	@Default(.hasCompletedOnboarding) private var hasCompletedOnboarding
	@State private var pages: [OnboardingPage] = []
	@State private var pageContexts: [String: OnboardingPageContext] = [:]
	@State private var selectedID = ""
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	var body: some View {
		GeometryReader { geometry in
			ZStack {
				OnboardingBackground(currentPageID: selectedID)
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
					}
				}
			}
		}
		.safeAreaBar(edge: .bottom, alignment: .center, spacing: 0) {
			controls
				.ignoresSafeArea()
		}
		.task { await buildPages() }
	}

	@ViewBuilder
	private func pageView(_ page: OnboardingPage) -> some View {
		if let context = pageContexts[page.id] {
			VStack(spacing: 24) {
				Text(page.title)
					.font(.largeTitle.bold())
					.multilineTextAlignment(.center)
				page.content()
					.frame(maxWidth: 620, maxHeight: .infinity)
				Text(context.statusMessage ?? " ")
					.contentTransition(.opacity)
					.font(.callout)
					.multilineTextAlignment(.center)
					.opacity(context.statusMessage == nil ? 0 : 1)
					.frame(minHeight: 20)
					.padding(.bottom, 20)
					.animation(.easeInOut, value: context.statusMessage)
			}
			.padding(.horizontal, 24)
			.padding(.top, 24)
			.environment(\.onboardingPageContext, context)
		}
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
			.buttonSizing(.flexible)
			.font(.title3)
			.buttonStyle(.glassProminent)
			.controlSize(.extraLarge)
			.disabled(selectedIndex == 0 || selectedContext?.isWorking == true)

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

					Image(systemName: "chevron.right")
				}
			}
			.buttonSizing(.flexible)
			.font(.title3)
			.buttonStyle(.glassProminent)
			.controlSize(.extraLarge)
			.disabled(selectedContext?.canAdvance != true || selectedContext?.isWorking == true || pages.isEmpty)
		}
		.padding(.horizontal, 30)
	}

	private var selectedIndex: Int {
		pages.firstIndex(where: { $0.id == selectedID }) ?? 0
	}

	private var selectedContext: OnboardingPageContext? {
		pageContexts[selectedID]
	}

	private func move(by offset: Int) {
		let destination = selectedIndex + offset
		guard pages.indices.contains(destination) else { return }
		selectedID = pages[destination].id
	}

	private func buildPages(preserving currentID: String? = nil) async {
		let calendarGranted = EKEventStore.authorizationStatus(for: .event) == .fullAccess
		let notificationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
		let notificationGranted = [.authorized, .provisional, .ephemeral].contains(notificationStatus)

		let candidates = makePages(calendarGranted: calendarGranted, notificationGranted: notificationGranted)
		let visiblePages = candidates.filter { $0.isVisible() }
		var retainedContexts: [String: OnboardingPageContext] = [:]
		for page in visiblePages {
			retainedContexts[page.id] = pageContexts[page.id] ?? makeContext(for: page.id)
		}
		pageContexts = retainedContexts
		pages = visiblePages
		let retainedID = currentID.flatMap { id in visiblePages.contains(where: { $0.id == id }) ? id : nil }
		selectedID = retainedID ?? visiblePages.first?.id ?? ""
	}

	private func makeContext(for pageID: String) -> OnboardingPageContext {
		switch pageID {
			case "splash", "welcome", "finished":
				OnboardingPageContext(canAdvance: true)
			default:
				OnboardingPageContext()
		}
	}

	private func makePages(calendarGranted: Bool, notificationGranted: Bool) -> [OnboardingPage] {
		[
			OnboardingPage(id: "splash", title: "") {
				SplashView()
			},
			OnboardingPage(id: "calendar", title: "Calendar Access", isVisible: {
				#if DEBUG
					true
				#else
					!calendarGranted
				#endif
			}) {
				OnboardingCalendarPermissionView()
			},
			OnboardingPage(id: "calendar-import", title: "Import Your Timetable") {
				OnboardingCalendarImportView()
			},
			OnboardingPage(id: "notifications", title: "Notifications", isVisible: {
				#if DEBUG
					true
				#else
					!notificationGranted
				#endif
			}) {
				OnboardingNotificationPermissionView()
			},
			OnboardingPage(id: "apns", title: "Register This Device") {
				OnboardingAPNsRegistrationView()
			},
			OnboardingPage(id: "account", title: "Your Account") {
				OnboardingAccountView()
			},
			OnboardingPage(id: "finished", title: "Ready to Begin") {
//				OnboardingSimplePage(systemImage: "checkmark.circle.fill", text: "Timetable is configured for this device.")
				Text("")
			},
		]
	}
}
