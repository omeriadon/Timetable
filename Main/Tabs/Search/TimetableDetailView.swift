//
//  TimetableDetailView.swift
//  Timetable
//
//  Created by Adon Omeri on 1/7/2026.
//

import PortalHeaders
import PortalTransitions
import SwiftUI

struct TimetableDetailView: View {
	let result: TimetableSearchResult
	let portalNamespace: Namespace.ID
	@State private var detail: TimetableDetailResponse?
	@State private var showReportConfirmation = false
	@State private var isWorking = true
	@State private var imported = false
	@Environment(\.statusBadgeManager) private var badges
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			ZStack {
				ScrollView {
					TimetableIdentityView(result: result, prominence: .header)
						.portal(item: result, as: .destination, in: portalNamespace)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.horizontal)

					if let detail {
						VStack(alignment: .leading, spacing: 20) {
							TimetablePreviewGrid(subjects: detail.subjects)

							if detail.sourceKind != .accountOwner {
								Label("This timetable is an authored timetable, which means this user has created this timetable for someone else. The contents of this timetable are not verified.", systemImage: "exclamationmark.triangle")
									.foregroundStyle(.secondary)
									.font(.callout)
							}
							Text("\(detail.savedByCount) \(detail.savedByCount == 1 ? "person has" : "people have") saved this timetable.")

							if let updatedAt = detail.updatedAt {
								LabeledContent("Updated") {
									Text(updatedAt, format: .dateTime.day().month().year())
								}
							}
						}
						.padding()
					} else {
						ProgressView()
							.frame(maxWidth: .infinity)
							.padding(.top, 80)
					}
				}
				.scrollBounceBehavior(.basedOnSize)
				.scrollEdgeEffectStyle(.soft, for: .bottom)
				.scrollEdgeEffectStyle(.soft, for: .top)
			}
			.animation(.easeIn(duration: 0.1), value: detail == nil)
			.safeAreaBar(edge: .bottom, alignment: .center, spacing: 10) {
				ZStack {
					if imported {
						Label("Saved", systemImage: "checkmark.circle.fill")
							.foregroundStyle(.green)
							.transition(.blurReplace)
					} else if isWorking {
						ProgressView()
							.transition(.blurReplace)
					} else {
						Button("Save Timetable", systemImage: "square.and.arrow.down", action: importTimetable)
							.buttonStyle(.glassProminent)
							.controlSize(.large)
							.buttonSizing(.flexible)
							.transition(.blurReplace)
					}
				}
				.frame(height: 50)
				.animation(.easeInOut, value: "\(imported)\(isWorking)")
				.padding([.bottom, .horizontal], 20)
			}
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
				}

				ToolbarItem(placement: .topBarTrailing) {
					Button("Report Author", systemImage: "exclamationmark.bubble", role: .destructive) { showReportConfirmation = true }
						.confirmationDialog("Report \(result.authorDisplayName)?", isPresented: $showReportConfirmation) {
							Button("Report Author", role: .destructive) { Task { await report() } }
							Button("Cancel", role: .cancel) {}
						} message: {
							Text("This reports the author account to Timetable moderation.")
						}
				}
			}
			.task { await load() }
		}
		.monospaced()
	}

	private func load() async {
		do { detail = try await TimetableDiscoveryService.shared.detail(id: result.id) } catch { show(error, title: "Unable to load timetable") }
		isWorking = false
	}

	private func importTimetable() {
		guard SessionStore.shared.isAuthenticated else {
			showSignInRequired()
			return
		}

		isWorking = true

		Task {
			defer { isWorking = false }

			do {
				_ = try await ReceivedTimetableSyncService.shared.importTimetable(id: result.id)
				imported = true
				badges.addBadge(id: UUID(), title: "Timetable saved", priority: 3, view: .success)
			} catch {
				show(error, title: "Unable to save timetable")
			}
		}
	}

	private func report() async {
		guard SessionStore.shared.isAuthenticated else {
			showSignInRequired()
			return
		}

		do {
			try await TimetableDiscoveryService.shared.report(authorID: result.authorAccountID)
			badges.addBadge(id: UUID(), title: "Author reported", priority: 3, view: .success)
		} catch {}
	}

	private func show(_ error: any Error, title: String) {
		if let networkError = error as? NetworkError, networkError.suppressesStatusBadge {
			return
		}
		badges.addBadge(id: UUID(), title: title, secondaryText: error.localizedDescription, priority: 4, view: .error)
	}

	private func showSignInRequired() {
		badges.signInRequired()
	}
}
