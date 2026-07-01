//
//  TimetableSearchView.swift
//  Timetable
//
//  Created by Adon Omeri on 1/7/2026.
//

import PassKit
import PortalTransitions
import Sticker
import SwiftUI

struct TimetableSearchView: View {
	@State private var query = ""
	@State private var service = TimetableDiscoveryService.shared
	@State private var sessionStore = SessionStore.shared
	@State private var selectedResult: TimetableSearchResult?
	@State private var isSearchPresented = false
	@Namespace private var portalNamespace

	var body: some View {
		PortalContainer {
			NavigationStack {
				ZStack {
					if !sessionStore.isAuthenticated {
						ContentUnavailableView("Sign In Required", systemImage: "person.crop.circle.badge.exclamationmark", description: Text("Sign in to search timetables."))
							.transition(.blurReplace)

					} else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
						SearchLandingView()
							.transition(.blurReplace)

					} else if !(3 ..< 50).contains(query.trimmingCharacters(in: .whitespacesAndNewlines).count) {
						ContentUnavailableView("Keep Typing", systemImage: "text.magnifyingglass", description: Text("Search terms must contain 3 to 49 characters."))
							.transition(.blurReplace)

					} else if service.results.isEmpty, !service.isSearching {
						ContentUnavailableView.search(text: query)
							.transition(.blurReplace)
					} else {
						List {
							ForEach(service.results) { result in
								Button {
									selectedResult = result
								} label: {
									TimetableSearchRow(result: result, namespace: portalNamespace)
								}
								.buttonStyle(.plain)
								.listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
							}
						}
						.animation(.snappy, value: service.results.map(\.id))
						.refreshable { service.search(query, immediately: true) }
						.transition(.blurReplace)
					}
				}
				.animation(.easeOut(duration: 0.25), value: "\(sessionStore.isAuthenticated)\(query)\(service.results.isEmpty)\(service.isSearching)")
				.toolbar {
					if !isSearchPresented {
						ToolbarItem(placement: .largeTitle) {
							Text("Search")
								.monospaced()
								.font(.largeTitle)
								.bold()
						}
					}
				}
				.navigationBarTitleDisplayMode(.large)
				.overlay {
					ZStack {
						if service.isSearching {
							ProgressView().controlSize(.large)
								.transition(.blurReplace)
						}
					}
					.animation(.easeInOut(duration: 0.2), value: service.isSearching)
				}
				.searchable(text: $query, isPresented: $isSearchPresented, prompt: "Timetable or author")
				.onChange(of: query) {
					if sessionStore.isAuthenticated { service.search(query) }
				}
			}
			.sheet(item: $selectedResult) { result in
				TimetableDetailView(result: result, portalNamespace: portalNamespace)
			}
		}
	}
}

private struct SearchLandingView: View {
	@State private var isInteracting = false

	var body: some View {
		VStack(spacing: 25) {
			Image("PlaceholderTimetablePass")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(maxWidth: .infinity)
				.padding(.horizontal, 100)
				.animation(.spring(duration: 0.5, bounce: 0.6, blendDuration: 0)) { view in
					view
						.scaleEffect(isInteracting ? 1.05 : 0.95)
						.stickerEffect()
						.stickerPattern(.diamond)
						.stickerNoiseScale(450)
						.stickerNoiseIntensity(1)
						.stickerColorIntensity(1)
						.stickerMotionEffect(.dragGesture(intensity: 0.7))
				}
				.simultaneousGesture(
					DragGesture(minimumDistance: 0)
						.onChanged { _ in
							isInteracting = true
						}
						.onEnded { _ in
							isInteracting = false
						}
				)

			Text("Search for a timetable by name or author.")
				.multilineTextAlignment(.center)
				.font(.title2)
				.bold()
		}
	}
}

private struct TimetableSearchRow: View {
	let result: TimetableSearchResult
	let namespace: Namespace.ID

	var body: some View {
		HStack(spacing: 16) {
			Image(systemName: result.sourceKind == .accountOwner ? "person.crop.rectangle" : "person.2.crop.square.stack")
				.font(.title2).foregroundStyle(.tint).frame(width: 34)
			TimetableIdentityView(result: result, prominence: .row)
				.portal(item: result, as: .source, in: namespace)
		}
		.frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
		.contentShape(.rect)
		.accessibilityElement(children: .combine)
	}
}
