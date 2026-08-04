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
	@Default(.onboardingPageID) private var onboardingPageID
	@Default(.hasCompletedAccountBootstrap) private var hasCompletedAccountBootstrap
	@Default(.timetable) private var subjects
	@State private var sessionStore = SessionStore.shared
	@State private var pages: [OnboardingPage] = []
	@State private var pageContexts: [String: OnboardingPageContext] = [:]
	@State private var selectedID = ""
	@State private var pageBuildGeneration = 0
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
					.onChange(of: selectedID, initial: true) { oldID, newID in
						if !newID.isEmpty {
							onboardingPageID = newID
						}
						guard !newID.isEmpty else { return }
						guard !oldID.isEmpty, oldID != newID else {
							proxy.scrollTo(newID, anchor: .center)
							return
						}
						withAnimation(reduceMotion ? .none : .smooth(duration: 0.65)) {
							proxy.scrollTo(newID, anchor: .center)
						}
					}
				}
			}
		}
		.scrollEdgeEffect()
		.scrollEdgeEffect(direction: .clearTopDarkBottom, offset: 0.85)
		.safeAreaBar(edge: .top, alignment: .center, spacing: 0) {
			Text(pages.first(where: { $0.id == selectedID })?.title ?? " ")
				.font(.title.bold())
				.multilineTextAlignment(.center)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 8)
				.contentTransition(.numericText())
				.animation(.easeInOut, value: selectedID)
		}
		.safeAreaBar(edge: .bottom, alignment: .center, spacing: 0) {
			VStack {
				VStack {
					if let context = selectedContext {
						Text(context.statusMessage ?? "")
							.contentTransition(.numericText())
							.animation(.easeInOut, value: context.statusMessage)
							.font(.footnote)
							.multilineTextAlignment(.center)
							.frame(maxWidth: .infinity)
							.frame(minHeight: 20)
					}
				}
				HStack(spacing: 0) {
					left

					Spacer()

					middle

					Spacer()

					right
				}
			}
			.padding(.horizontal, 20)
			.padding(.bottom, -12)
			.padding(.top, 5)
		}
		.task(id: pageBuildGeneration) {
			await buildPages(preserving: selectedID)
		}
		.onChange(of: sessionStore.state) {
			pageBuildGeneration += 1
		}
		.onChange(of: hasCompletedAccountBootstrap) {
			pageBuildGeneration += 1
		}
		.onChange(of: subjects) {
			pageBuildGeneration += 1
		}
	}

	@ViewBuilder
	private func pageView(_ page: OnboardingPage) -> some View {
		if let context = pageContexts[page.id] {
			OnboardingPageContent(kind: page.kind, context: context)
				.scrollEdgeEffectStyle(.none, for: .vertical)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
				.padding(.horizontal, 24)
		}
	}

	var left: some View {
		Button {
			move(by: -1)
		} label: {
			Image(systemName: "chevron.left")
				.foregroundStyle(.white)
				.contentShape(.circle)
		}
		.buttonSizing(.fitted)
		.buttonBorderShape(.circle)
		.font(.title)
		.buttonStyle(.glassProminent)
		.controlSize(.extraLarge)
		.disabled(isBackDisabled)
		.animation(.easeInOut, value: selectedIndex)
	}

	var middle: some View {
		VStack(spacing: 5) {
			Text("\(min(selectedIndex + 1, pages.count)) of \(pages.count)")
				.contentTransition(.numericText())
			ProgressView(value: pages.isEmpty ? 0 : Double(selectedIndex + 1), total: Double(max(pages.count, 1)))
				.progressViewStyle(.linear)
				.frame(width: 90)
		}
		.animation(.easeInOut, value: selectedIndex)
	}

	var right: some View {
		Button {
			if selectedIndex == pages.count - 1 {
				hasCompletedOnboarding = true
				onboardingPageID = ""
			} else {
				move(by: 1)
			}
		} label: {
			Image(systemName: !(selectedIndex == pages.count - 1) ? "chevron.right" : "checkmark")
				.contentTransition(.symbolEffect(.replace.upUp.wholeSymbol, options: .nonRepeating))
				.foregroundStyle(.white)
				.contentShape(.circle)
				.animation(.easeInOut, value: selectedIndex)
		}
		.buttonSizing(.fitted)
		.font(.title)
		.buttonBorderShape(.circle)
		.buttonStyle(.glassProminent)
		.controlSize(.extraLarge)
		.disabled(isNextDisabled)
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
		guard !Task.isCancelled else {
			return
		}
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
		let visiblePages = candidates.filter(\.isVisible)
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
		isAuthenticated: Bool,
		hasServerTimetable: Bool
	) -> [OnboardingPage] {
		[
			OnboardingPage(id: "splash", title: "    ", kind: .splash),
			OnboardingPage(
				id: "calendar",
				title: "Calendar Access",
				kind: .calendarPermission,
				isVisible: {
					#if DEBUG
						return true
					#else
						return !calendarGranted
					#endif
				}()
			),
			OnboardingPage(id: "account", title: "Your Account", kind: .account),
			OnboardingPage(id: "year-group", title: "Your Year Group", kind: .yearGroup, isVisible: isAuthenticated),
			OnboardingPage(id: "calendar-import", title: "Import Your Timetable", kind: .calendarImport, isVisible: !hasServerTimetable),
			OnboardingPage(
				id: "notifications",
				title: "Notifications",
				kind: .notifications,
				isVisible: {
					#if DEBUG
						return true
					#else
						return !notificationGranted
					#endif
				}()
			),
			OnboardingPage(id: "actualFinished", title: "Ready to use Timetable!", kind: .completion),
		]
	}
}

private struct OnboardingPageContent: View {
	let kind: OnboardingPage.Kind
	let context: OnboardingPageContext

	var body: some View {
		switch kind {
			case .splash:
				SplashView()
			case .calendarPermission:
				OnboardingCalendarPermissionView(context: context)
			case .account:
				OnboardingAccountView(context: context)
			case .yearGroup:
				OnboardingYearGroupView(context: context)
			case .calendarImport:
				OnboardingCalendarImportView(context: context)
			case .notifications:
				OnboardingNotificationPermissionView(context: context)
			case .completion:
				OnboardingCompletion(context: context)
		}
	}
}
