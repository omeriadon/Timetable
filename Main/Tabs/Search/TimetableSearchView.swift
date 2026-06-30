import PassKit
import SwiftUI

struct TimetableSearchView: View {
	@State private var query = ""
	@State private var service = TimetableDiscoveryService.shared
	@State private var sessionStore = SessionStore.shared

	var body: some View {
		NavigationStack {
			Group {
				if !sessionStore.isAuthenticated {
					ContentUnavailableView("Sign In Required", systemImage: "person.crop.circle.badge.exclamationmark", description: Text("Sign in to search timetables."))
				} else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
					SearchLandingView()
				} else if !(3 ..< 50).contains(query.trimmingCharacters(in: .whitespacesAndNewlines).count) {
					ContentUnavailableView("Keep Typing", systemImage: "text.magnifyingglass", description: Text("Search terms must contain 3 to 49 characters."))
				} else if service.results.isEmpty, !service.isSearching {
					ContentUnavailableView.search(text: query)
				} else {
					List(service.results) { result in
						NavigationLink(value: result) { TimetableSearchRow(result: result) }
							.listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
					}
					.animation(.snappy, value: service.results.map(\.id))
					.refreshable { service.search(query, immediately: true) }
				}
			}
			.overlay { if service.isSearching { ProgressView().controlSize(.large) } }
			.appNavigationTitle("Search")
			.searchable(text: $query, prompt: "Timetable or author")
			.onChange(of: query) { if sessionStore.isAuthenticated { service.search(query) } }
			.navigationDestination(for: TimetableSearchResult.self) { TimetableDetailView(result: $0) }
		}
	}
}

private struct SearchLandingView: View {
	var body: some View {
		ContentUnavailableView("Search Timetables", systemImage: "magnifyingglass", description: Text("Enter at least three characters."))
	}
}

private struct TimetableSearchRow: View {
	let result: TimetableSearchResult
	var body: some View {
		HStack(spacing: 16) {
			Image(systemName: result.sourceKind == .accountOwner ? "person.crop.rectangle" : "person.2.crop.square.stack")
				.font(.title2).foregroundStyle(.tint).frame(width: 34)
			VStack(alignment: .leading, spacing: 6) {
				Text(result.title).font(.headline).lineLimit(2)
				Text(result.authorDisplayName).foregroundStyle(.secondary).lineLimit(1)
			}
		}
		.frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
	}
}

private struct TimetableDetailView: View {
	let result: TimetableSearchResult
	@State private var detail: TimetableDetailResponse?
	@State private var pass: PKPass?
	@State private var showReportConfirmation = false
	@State private var isWorking = false
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		ScrollView {
			if let detail {
				VStack(alignment: .leading, spacing: 20) {
					VStack(alignment: .leading, spacing: 4) { Text(detail.title).font(.title.bold()); Text("By \(detail.authorDisplayName)").foregroundStyle(.secondary) }
					TimetablePreviewGrid(subjects: detail.subjects)
					LabeledContent("Type", value: detail.sourceKind == .accountOwner ? "Owner timetable" : "Authored timetable")
					LabeledContent("Subjects", value: "\(detail.subjectCount)")
					LabeledContent("Weekly lessons", value: "\(detail.weeklyLessonCount)")
					LabeledContent("Active installs", value: "\(detail.activeInstallCount)")
					if let updatedAt = detail.updatedAt { LabeledContent("Updated") { Text(updatedAt, format: .dateTime.day().month().year()) } }
					#if os(iOS)
						if let pass {
							AddPassToWalletButton([pass]) { added in if added { badges.addBadge(id: UUID(), title: "Pass added to Wallet", priority: 3, view: .success) } }.addPassToWalletButtonStyle(.black).frame(height: 52)
						} else {
							Button("Download Apple Wallet Pass", systemImage: "wallet.pass", action: download).buttonStyle(.borderedProminent).disabled(isWorking)
						}
					#endif
					Button("Report Author", systemImage: "exclamationmark.bubble", role: .destructive) { showReportConfirmation = true }
				}
				.padding()
			} else { ProgressView().frame(maxWidth: .infinity, minHeight: 300) }
		}
		.appNavigationTitle(result.title)
		#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
		#endif
			.task { await load() }
			.confirmationDialog("Report \(result.authorDisplayName)?", isPresented: $showReportConfirmation) {
				Button("Report Author", role: .destructive) { Task { await report() } }
				Button("Cancel", role: .cancel) {}
			} message: { Text("This reports the author account to Timetable moderation.") }
	}

	private func load() async {
		do { detail = try await TimetableDiscoveryService.shared.detail(id: result.id) } catch { show(error, title: "Unable to load timetable") }
	}

	private func download() {
		guard SessionStore.shared.isAuthenticated else { showSignInRequired(); return }; isWorking = true; Task { defer { isWorking = false }; do { pass = try await WalletPassService.shared.downloadPass(timetableID: result.id) } catch { show(error, title: "Unable to download pass") } }
	}

	private func report() async {
		guard SessionStore.shared.isAuthenticated else { showSignInRequired(); return }; do { try await TimetableDiscoveryService.shared.report(authorID: result.authorAccountID); badges.addBadge(id: UUID(), title: "Author reported", priority: 3, view: .success) } catch { show(error, title: "Unable to report author") }
	}

	private func show(_ error: any Error, title: String) {
		if let networkError = error as? NetworkError, networkError.suppressesStatusBadge { return }; badges.addBadge(id: UUID(), title: title, secondaryText: error.localizedDescription, priority: 4, view: .error)
	}

	private func showSignInRequired() {
		badges.addBadge(id: UUID(), title: "Sign in required", secondaryText: "Sign in to use this feature.", priority: 3, view: .warning)
	}
}
