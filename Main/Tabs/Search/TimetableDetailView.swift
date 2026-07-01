//
//  TimetableDetailView.swift
//  Timetable
//
//  Created by Adon Omeri on 1/7/2026.
//

import PassKit
import PortalTransitions
import SwiftUI

struct TimetableDetailView: View {
	let result: TimetableSearchResult
	let portalNamespace: Namespace.ID
	@State private var detail: TimetableDetailResponse?
	@State private var pass: PKPass?
	@State private var showReportConfirmation = false
	@State private var isWorking = true
	@State private var passLoadFailed = false
	@Environment(\.statusBadgeManager) private var badges
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			ZStack {
				ScrollView {
					TimetableIdentityView(result: result, prominence: .header)
						.padding(.horizontal)
						.portal(item: result, as: .destination, in: portalNamespace)

					if let detail {
						VStack(alignment: .leading, spacing: 20) {
							TimetablePreviewGrid(subjects: detail.subjects)

							if detail.sourceKind != .accountOwner {
								Label("This timetable is an authored timetable, which means this user has created this timetable for someone else. The contents of this timetable are not verified.", systemImage: "exclamationmark.triangle")
									.foregroundStyle(.secondary)
									.font(.callout)
							}
							Text("\(detail.activeInstallCount) \(detail.activeInstallCount == 1 ? "user has" : "users have") downloaded this pass.")

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
				.scrollEdgeEffectStyle(.soft, for: .bottom)
				.scrollEdgeEffectStyle(.soft, for: .top)
			}
			.animation(.easeIn(duration: 0.1), value: detail == nil)
			.safeAreaBar(edge: .bottom, alignment: .center, spacing: 10) {
				ZStack {
					if let pass {
						AddPassToWalletButton([pass]) {
							added in if added { badges.addBadge(id: UUID(), title: "Pass added to Wallet", priority: 3, view: .success) }
						}
						.addPassToWalletButtonStyle(.black)
						.clipShape(.capsule)
						.transition(.blurReplace)

					} else if isWorking {
						ProgressView()
							.transition(.blurReplace)
					} else if passLoadFailed {
						Button("Retry Pass Download", systemImage: "arrow.clockwise", action: download)
							.buttonStyle(.glass)
							.transition(.blurReplace)
					}
				}
				.frame(height: 50)
				.animation(.easeInOut, value: pass == nil)
				.padding([.bottom, .horizontal], 20)
			}
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
				}

				ToolbarItem(placement: .topBarPinnedTrailing) {
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
		async let detailResult = TimetableDiscoveryService.shared.detail(id: result.id)
		async let passResult = WalletPassService.shared.downloadPass(timetableID: result.id)
		do { detail = try await detailResult } catch { show(error, title: "Unable to load timetable") }
		do {
			pass = try await passResult
			passLoadFailed = false
		} catch is CancellationError {
			return
		} catch {
			passLoadFailed = true
			show(error, title: "Unable to download pass")
		}
		isWorking = false
	}

	private func download() {
		guard SessionStore.shared.isAuthenticated else {
			showSignInRequired()
			return
		}

		isWorking = true
		passLoadFailed = false

		Task {
			defer { isWorking = false }

			do {
				pass = try await WalletPassService.shared.downloadPass(timetableID: result.id)
			} catch {
				show(error, title: "Unable to download pass")
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
		if let networkError = error as? NetworkError, networkError.suppressesStatusBadge { return }
		badges.addBadge(id: UUID(), title: title, secondaryText: error.localizedDescription, priority: 4, view: .error)
	}

	private func showSignInRequired() {
		badges.addBadge(id: UUID(), title: "Sign in required", secondaryText: "Sign in to use this feature.", priority: 3, view: .warning)
	}
}
