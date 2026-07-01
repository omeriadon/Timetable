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
	@State private var portalResult: TimetableSearchResult?
	@State private var completedSearchQuery = ""
	@State private var isSearchPresented = false

	@Namespace private var portalNamespace

	private var cleanedQuery: String {
		query.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	var body: some View {
		PortalContainer {
			NavigationStack {
				ZStack {
					if !sessionStore.isAuthenticated {
						ContentUnavailableView("Sign In Required", systemImage: "person.crop.circle.badge.exclamationmark", description: Text("Sign in to search timetables."))
							.transition(.blurReplace)

					} else if cleanedQuery.isEmpty {
						SearchLandingView()
							.transition(.blurReplace)

					} else if !(3 ..< 50).contains(cleanedQuery.count) {
						ContentUnavailableView("Keep Typing", systemImage: "text.magnifyingglass", description: Text("Search terms must contain 3 to 49 characters."))
							.transition(.blurReplace)

					} else if service.results.isEmpty,
					          service.isSearching || completedSearchQuery != cleanedQuery
					{
						Color.clear
							.transition(.blurReplace)
					} else if service.results.isEmpty,
					          !service.isSearching,
					          completedSearchQuery == cleanedQuery
					{
						ContentUnavailableView.search(text: cleanedQuery)
							.transition(.blurReplace)
					} else {
						List {
							ForEach(service.results) { result in
								Button {
									present(result)
								} label: {
									TimetableSearchRow(result: result, namespace: portalNamespace)
								}
								.buttonStyle(.plain)
								.listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
							}
						}
						.animation(.snappy, value: service.results.map(\.id))
						.refreshable { service.search(query, immediately: true) }
						.scrollEdgeEffectStyle(.soft, for: .top)
						.scrollEdgeEffectStyle(.soft, for: .bottom)
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
					.animation(.easeInOut(duration: 0.25), value: service.isSearching)
				}
				.searchable(text: $query, isPresented: $isSearchPresented, prompt: "Search a Timetable or Author")
				.onChange(of: query) {
					let cleaned = cleanedQuery

					completedSearchQuery = ""

					if sessionStore.isAuthenticated {
						service.search(cleaned)
					}
				}
				.onChange(of: service.isSearching) { _, isSearching in
					if !isSearching {
						completedSearchQuery = cleanedQuery
					}
				}
			}
			.sheet(item: $selectedResult) { result in
				TimetableDetailView(result: result, portalNamespace: portalNamespace)
			}
			.portalTransition(
				item: $portalResult,
				in: portalNamespace,
				animation: .smooth(duration: 0.48),
				transition: .fade
			) { _ in
				AnimatedItemLayer(item: $portalResult, in: portalNamespace) { item, isActive in
					if let item {
						TimetablePortalIdentityView(
							result: item,
							isActive: isActive
						)
						.animation(.smooth(duration: 0.48), value: isActive)
					}
				}
			}
			.onChange(of: selectedResult?.id) {
				if selectedResult == nil { portalResult = nil }
			}
		}
	}

	private func present(_ result: TimetableSearchResult) {
		portalResult = result
		selectedResult = result
	}
}

struct SearchLandingView: View {
	@State private var isInteracting = false

	var body: some View {
		VStack(spacing: 25) {
			Image("PlaceholderTimetablePass")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(maxWidth: .infinity)
				.padding(.horizontal, 100)
				.animation(.spring(duration: 0.5, bounce: 0.8, blendDuration: 0)) { view in
					view
						.scaleEffect(isInteracting ? 1.05 : 0.95)
						.stickerEffect()
						.stickerPattern(.diamond)
						.stickerNoiseScale(450)
						.stickerNoiseIntensity(1)
						.stickerColorIntensity(1)
						.stickerMotionEffect(.dragGesture(intensity: 0.7))
				}
				.shadow(color: .blue.mix(with: .white, by: 0.5).opacity(0.35), radius: 17, x: 0, y: 0)
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
		}
	}
}

private struct TimetableSearchRow: View {
	let result: TimetableSearchResult
	let namespace: Namespace.ID

	var body: some View {
		HStack(spacing: 12) {
			Image(systemName: result.sourceKind == .accountOwner
				? "person.crop.rectangle"
				: "person.2.crop.square.stack")
				.imageScale(.large)
				.foregroundStyle(.tint)
				.frame(width: 32)

			TimetableIdentityView(result: result, prominence: .row)
				.portal(item: result, as: .source, in: namespace)
		}
		.frame(height: 60)
	}
}
