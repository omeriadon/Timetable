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
	@Default(.hasSeenOnboardingBefore) private var hasSeenOnboardingBefore
	@Default(.onboardingPageID) private var onboardingPageID
	@Default(.hasCompletedAccountBootstrap) private var hasCompletedAccountBootstrap
	@Default(.timetable) private var subjects
	@State private var sessionStore = SessionStore.shared
	@State private var pages: [OnboardingPage] = []
	@State private var pageContexts: [String: OnboardingPageContext] = [:]
	@State private var selectedID = ""
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	private var isBackDisabled: Bool {
		#if DEBUG
			selectedIndex == 0
		#else
			selectedIndex == 0 || selectedContext?.isWorking == true
		#endif
	}

	private var isNextDisabled: Bool {
		#if DEBUG
			pages.isEmpty
		#else
			selectedContext?.canAdvance != true
				|| selectedContext?.isWorking == true
				|| pages.isEmpty
		#endif
	}

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
						if !newID.isEmpty {
							onboardingPageID = newID
						}
						guard !oldID.isEmpty, oldID != newID else { return }
						withAnimation(reduceMotion ? .none : .smooth(duration: 0.65)) {
							proxy.scrollTo(newID, anchor: .center)
						}
					}
				}
			}
		}
		.safeAreaBar(edge: .top, alignment: .center, spacing: 0) {
			Text(pages.first(where: { $0.id == selectedID })?.title ?? "")
				.font(.title.bold())
				.multilineTextAlignment(.center)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 8)
		}
		.safeAreaBar(edge: .bottom, alignment: .center, spacing: 0) {
			VStack(spacing: 0) {
				if let context = selectedContext {
					Text(context.statusMessage ?? " ")
						.contentTransition(.opacity)
						.font(.footnote)
						.multilineTextAlignment(.center)
						.opacity(context.statusMessage == nil ? 0 : 1)
						.frame(maxWidth: .infinity)
						.frame(minHeight: 20)
						.padding(.bottom, 20)
						.padding(.top, 8)
						.animation(.easeInOut, value: context.statusMessage)
				}
				controls
			}
		}
		.task { await buildPages() }
		.onChange(of: sessionStore.state) {
			Task { await buildPages(preserving: selectedID) }
		}
		.onChange(of: hasCompletedAccountBootstrap) {
			Task { await buildPages(preserving: selectedID) }
		}
		.onChange(of: subjects) {
			Task { await buildPages(preserving: selectedID) }
		}
	}

	private func pageView(_ page: OnboardingPage) -> some View {
		ZStack {
			if let context = pageContexts[page.id] {
				page.content()
					.scrollEdgeEffectStyle(.none, for: .vertical)
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
					.padding(.horizontal, 24)
					.environment(\.onboardingPageContext, context)
			}
		}
	}

	private var controls: some View {
		HStack(spacing: 0) {
			Button {
				move(by: -1)
			} label: {
				HStack {
					Image(systemName: "chevron.left")

					Text("Back")
				}
			}
			.buttonSizing(.fitted)
			.font(.headline)
			.buttonStyle(.glassProminent)
			.controlSize(.extraLarge)
			.disabled(isBackDisabled)
			.animation(.easeInOut, value: selectedIndex)

			Spacer(minLength: 1)

			VStack(spacing: 5) {
				Text("\(min(selectedIndex + 1, pages.count)) of \(pages.count)")
					.contentTransition(.numericText())
				ProgressView(value: pages.isEmpty ? 0 : Double(selectedIndex + 1), total: Double(max(pages.count, 1)))
					.progressViewStyle(.linear)
					.frame(width: 90)
			}
			.animation(.easeInOut, value: selectedIndex)

			Spacer(minLength: 1)

			Button {
				if selectedIndex == pages.count - 1 {
					hasCompletedOnboarding = true
					hasSeenOnboardingBefore = true
					onboardingPageID = ""
				} else {
					move(by: 1)
				}
			} label: {
				HStack {
					Text(selectedIndex == pages.count - 1 ? "Finish" : "Next")

					if !(selectedIndex == pages.count - 1) {
						Image(systemName: "chevron.right")
					}
				}
				.animation(.easeInOut, value: selectedIndex)
			}
			.buttonSizing(.fitted)
			.font(.headline)
			.buttonStyle(.glassProminent)
			.controlSize(.extraLarge)
			.disabled(isNextDisabled)
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

		let isAuthenticated = sessionStore.isAuthenticated
		let hasServerTimetable = OnboardingStateLogic.shouldSkipCalendarImport(
			isAuthenticated: isAuthenticated,
			bootstrapCompleted: hasCompletedAccountBootstrap,
			timetableIsEmpty: subjects.isEmpty
		)
		let candidates = makePages(
			calendarGranted: calendarGranted,
			notificationGranted: notificationGranted,
			isAuthenticated: isAuthenticated,
			hasServerTimetable: hasServerTimetable
		)
		let visiblePages = candidates.filter { $0.isVisible() }
		var retainedContexts: [String: OnboardingPageContext] = [:]
		for page in visiblePages {
			retainedContexts[page.id] = pageContexts[page.id] ?? makeContext(for: page.id)
		}
		pageContexts = retainedContexts
		pages = visiblePages
		let retainedID = currentID.flatMap { id in visiblePages.contains(where: { $0.id == id }) ? id : nil }
		selectedID = OnboardingStateLogic.restoredPageID(
			savedID: onboardingPageID,
			currentID: retainedID,
			visiblePageIDs: visiblePages.map(\.id)
		) ?? ""
	}

	private func makeContext(for pageID: String) -> OnboardingPageContext {
		switch pageID {
			case "splash", "welcome", "finished":
				OnboardingPageContext(canAdvance: true)
			default:
				OnboardingPageContext()
		}
	}

	private func makePages(
		calendarGranted: Bool,
		notificationGranted: Bool,
		isAuthenticated _: Bool,
		hasServerTimetable: Bool
	) -> [OnboardingPage] {
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
			OnboardingPage(id: "account", title: "Your Account") {
				OnboardingAccountView()
			},
			OnboardingPage(id: "calendar-import", title: "Import Your Timetable", isVisible: {
				!hasServerTimetable
			}) {
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
			OnboardingPage(id: "finished", title: "Ready to Begin") {
				OnboardingOverview()
			},
			OnboardingPage(id: "widget", title: "Widgets") {
				WidgetTutorial()
			},
			OnboardingPage(id: "notif", title: "Notifications") {
				NotifTutorial()
			},
			OnboardingPage(id: "share", title: "Share Timetables") {
				ShareTutorial()
			},
			OnboardingPage(id: "search", title: "Search Timetables") {
				SearchTutorial()
			},
			OnboardingPage(id: "friends", title: "Friends' Timetables") {
				FriendsTutorial()
			},
			OnboardingPage(id: "timetableTypes", title: "Timetable Types") {
				TimetableTypesTutorial()
			},
			OnboardingPage(id: "actualFinished", title: "Ready to use Timetable!") {
				OnboardingCompletion()
			},
		]
	}
}
