import Defaults
import SwiftUI

struct GradeTrackerView: View {
	@Default(.timetable) private var subjects
	@Default(.gradeTracker) private var document
	@Default(.eventTagCatalogue) private var tagCatalogue
	@Default(.eventTagSubscriptionIDs) private var subscriptionIDs
	@State private var service = GradeTrackerService.shared
	@State private var selectedSubject: Subject?
	@State private var showsATARSheet = false
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	var body: some View {
		ScrollView {
			LazyVStack(spacing: 14) {
				if isSenior {
					Button {
						showsATARSheet = true
					} label: {
						averageCard
					}
					.buttonStyle(.plain)
				} else {
					averageCard
				}

				if subjects.isEmpty {
					ContentUnavailableView(
						"No Subjects Yet",
						systemImage: "book.closed",
						description: Text("Add subjects to your timetable before tracking grades.")
					)
					.padding(.top, 72)
				} else {
					ForEach(subjects) { subject in
						Button {
							selectedSubject = subject
						} label: {
							GradeSubjectCard(
								subject: subject,
								average: subjectAverage(for: subject.id)
							)
						}
						.buttonStyle(.plain)
						.scrollTransition(.animated(.snappy(duration: 0.3))) { card, phase in
							card
								.opacity(reduceMotion || phase.isIdentity ? 1 : 0.65)
								.scaleEffect(reduceMotion || phase.isIdentity ? 1 : 0.96)
						}
					}
				}
			}
			.padding()
		}
		.scrollEdgeEffect()
		.appNavigationTitle("Grades", style: .main, accent: true)
		.sheet(item: $selectedSubject) { subject in
			GradeSubjectDetailView(subject: subject)
		}
		.sheet(isPresented: $showsATARSheet) {
			ATARSettingsSheet()
				.presentationDetents([.fraction(0.5)])
		}
		.task {
			try? await service.refresh()
		}
	}

	private var isSenior: Bool {
		let yearGroupTags = tagCatalogue.sections
			.filter { $0.category == .yearGroup }
			.flatMap(\.tags)
			.filter { subscriptionIDs.contains($0.id) }

		return yearGroupTags.contains { tag in
			let name = tag.displayName.lowercased()
			return name.contains("11") || name.contains("12")
		}
	}

	private var averageCard: some View {
		GradeAverageCard(
			average: overallAverage,
			predictedATAR: document.predictedATAR,
			goalATAR: document.goalATAR,
			showsATAR: isSenior
		)
	}

	private var overallAverage: Double? {
		let averages = subjects.compactMap { subjectAverage(for: $0.id) }
		guard !averages.isEmpty else {
			return nil
		}
		return averages.reduce(0, +) / Double(averages.count)
	}

	private func subjectAverage(for subjectID: String) -> Double? {
		let semesterAverages = [1, 2].compactMap { semesterAverage(subjectID: subjectID, semester: $0) }
		guard !semesterAverages.isEmpty else {
			return nil
		}
		return semesterAverages.reduce(0, +) / Double(semesterAverages.count)
	}

	private func semesterAverage(subjectID: String, semester: Int) -> Double? {
		let assessments = document.assessments.filter {
			$0.subjectID == subjectID && $0.semester == semester
		}
		let totalWeight = assessments.reduce(0) { $0 + $1.weighting }
		guard totalWeight > 0 else {
			return nil
		}
		return assessments.reduce(0) { $0 + ($1.score * $1.weighting) } / totalWeight
	}
}

private struct GradeAverageCard: View {
	let average: Double?
	let predictedATAR: Double?
	let goalATAR: Double?
	let showsATAR: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			HStack(alignment: .center, spacing: 18) {
				GradeGauge(value: average)

				VStack(alignment: .leading, spacing: 4) {
					Text("Overall Average")
					.font(.title2.weight(.semibold))
					Text(average.map { "\($0, specifier: "%.1f")%" } ?? "No assessments yet")
					.font(.title3)
					.foregroundStyle(.secondary)
				}
			}

			if showsATAR {
				HStack(spacing: 18) {
					ATARValue(title: "Predicted ATAR", value: predictedATAR)
					ATARValue(title: "Goal ATAR", value: goalATAR)
				}
			}
		}
		.padding(18)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(FriendPaperBackground(cornerRadius: 28))
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
		.foregroundStyle(.black)
	}
}

private struct GradeSubjectCard: View {
	let subject: Subject
	let average: Double?

	var body: some View {
		HStack(spacing: 14) {
			GradeGauge(value: average, tint: subject.colour.swiftUIColor)

			VStack(alignment: .leading, spacing: 5) {
				Text(subject.id)
					.font(.title3.weight(.semibold))
				Text(average.map { "\($0, specifier: "%.1f")% average" } ?? "No assessments yet")
					.foregroundStyle(.secondary)
			}

			Spacer()
			Image(systemName: "chevron.right")
				.foregroundStyle(.secondary)
		}
		.padding(14)
		.background(FriendPaperBackground(cornerRadius: 28))
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
		.foregroundStyle(.black)
	}
}

private struct GradeGauge: View {
	let value: Double?
	var tint: Color = .brown

	var body: some View {
		Gauge(value: value ?? 0, in: 0 ... 100) {
			Image(systemName: "chart.line.uptrend.xyaxis")
		} currentValueLabel: {
			Text(value.map { "\($0, specifier: "%.0f")%" } ?? "—")
			.font(.caption.bold())
		} minimumValueLabel: {
			EmptyView()
		} maximumValueLabel: {
			EmptyView()
		}
		.gaugeStyle(.accessoryCircularCapacity)
		.tint(tint)
		.frame(width: 68, height: 68)
	}
}

private struct ATARValue: View {
	let title: String
	let value: Double?

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(title)
				.font(.caption)
				.foregroundStyle(.secondary)
			Text(value.map { "\($0, specifier: "%.2f")" } ?? "Not set")
				.font(.headline)
		}
	}
}

private struct ATARSettingsSheet: View {
	@Default(.gradeTracker) private var document
	@State private var predictedATAR: Double?
	@State private var goalATAR: Double?
	@State private var service = GradeTrackerService.shared
	@Environment(\.dismiss) private var dismiss
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		NavigationStack {
			Form {
				Section("ATAR") {
					TextField("Predicted ATAR", value: $predictedATAR, format: .number.precision(.fractionLength(2)))
						.keyboardType(.decimalPad)
					TextField("Goal ATAR", value: $goalATAR, format: .number.precision(.fractionLength(2)))
						.keyboardType(.decimalPad)
				}
			}
			.appNavigationTitle("ATAR")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					}
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Save", systemImage: "checkmark", role: .confirm) {
						Task { await save() }
					}
					.buttonStyle(.glassProminent)
				}
			}
		}
		.task {
			predictedATAR = document.predictedATAR
			goalATAR = document.goalATAR
		}
	}

	private func save() async {
		var proposed = document
		proposed.predictedATAR = predictedATAR
		proposed.goalATAR = goalATAR
		do {
			try await service.save(proposed)
			dismiss()
		} catch {
			badges.present(error: error, title: "Unable to save ATAR goals")
		}
	}
}

private struct GradeSubjectDetailView: View {
	let subject: Subject
	@Default(.timetable) private var subjects
	@Default(.gradeTracker) private var document
	@State private var service = GradeTrackerService.shared
	@State private var editorContext: AssessmentEditorContext?
	@Environment(\.dismiss) private var dismiss
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		List {
			ForEach([1, 2], id: \.self) { semester in
				Section("Semester \(semester)") {
					Button {
						editorContext = AssessmentEditorContext(semester: semester)
					} label: {
						Label("New Assessment", systemImage: "plus")
					}

					ForEach(assessments(for: semester)) { assessment in
						Button {
							editorContext = AssessmentEditorContext(
								semester: semester,
								assessment: assessment
							)
						} label: {
							GradeAssessmentRow(assessment: assessment)
						}
						.buttonStyle(.plain)
					}
				}
			}
		}
		.appNavigationTitle(subject.id, accent: true)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button(role: .cancel) {
					dismiss()
				}
			}
		}
		.sheet(item: $editorContext) { context in
			GradeAssessmentEditor(
				subject: subject,
				semester: context.semester,
				assessment: context.assessment,
				subjects: subjects,
				save: save,
				delete: delete
			)
			.presentationDetents([.fraction(0.7)])
		}
	}

	private func assessments(for semester: Int) -> [GradeAssessment] {
		document.assessments
			.filter { $0.subjectID == subject.id && $0.semester == semester }
			.sorted { $0.date < $1.date }
	}

	private func save(_ assessment: GradeAssessment) async {
		var proposed = document
		proposed.assessments.removeAll { $0.id == assessment.id }
		proposed.assessments.append(assessment)
		do {
			try await service.save(proposed)
			editorContext = nil
		} catch {
			badges.present(error: error, title: "Unable to save assessment")
		}
	}

	private func delete(_ assessment: GradeAssessment) async {
		var proposed = document
		proposed.assessments.removeAll { $0.id == assessment.id }
		do {
			try await service.save(proposed)
			editorContext = nil
		} catch {
			badges.present(error: error, title: "Unable to delete assessment")
		}
	}
}

private struct AssessmentEditorContext: Identifiable {
	let id = UUID()
	let semester: Int
	let assessment: GradeAssessment?

	init(semester: Int, assessment: GradeAssessment? = nil) {
		self.semester = semester
		self.assessment = assessment
	}
}

private struct GradeAssessmentRow: View {
	let assessment: GradeAssessment

	var body: some View {
		HStack(spacing: 14) {
			GradeGauge(value: assessment.score, tint: .brown)

			VStack(alignment: .leading, spacing: 4) {
				Text(assessment.name)
					.font(.headline)
				Text(assessment.date.displayLabel)
					.font(.caption)
					.foregroundStyle(.secondary)
			}

			Spacer()

			VStack(alignment: .trailing, spacing: 4) {
				Text("\(assessment.score, specifier: "%.1f")%")
					.font(.headline)
				Text("Weight \(assessment.weighting, specifier: "%.1f")")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		}
		.padding(.vertical, 4)
	}
}

private struct GradeAssessmentEditor: View {
	let subject: Subject
	let semester: Int
	let assessment: GradeAssessment?
	let subjects: [Subject]
	let save: (GradeAssessment) async -> Void
	let delete: (GradeAssessment) async -> Void
	@State private var name: String
	@State private var date: Date
	@State private var score: Double
	@State private var weighting: Double
	@State private var location: GradeAssessmentLocation
	@State private var isSaving = false
	@Environment(\.dismiss) private var dismiss

	init(
		subject: Subject,
		semester: Int,
		assessment: GradeAssessment?,
		subjects: [Subject],
		save: @escaping (GradeAssessment) async -> Void,
		delete: @escaping (GradeAssessment) async -> Void
	) {
		self.subject = subject
		self.semester = semester
		self.assessment = assessment
		self.subjects = subjects
		self.save = save
		self.delete = delete
		_name = State(initialValue: assessment?.name ?? "")
		_date = State(initialValue: assessment?.date.date ?? Self.nextWeekday())
		_score = State(initialValue: assessment?.score ?? 0)
		_weighting = State(initialValue: assessment?.weighting ?? 1)
		_location = State(initialValue: assessment?.location ?? .exam)
	}

	var body: some View {
		NavigationStack {
			Form {
				Section("Assessment") {
					TextField("Name", text: $name)
					DatePicker("Date", selection: $date, displayedComponents: .date)
					Text("Selected: \(selectedLocationTitle)")
						.font(.caption)
						.foregroundStyle(.secondary)
					Picker("Assessment period", selection: $location) {
						ForEach(locationOptions, id: \.self) { option in
							Text(option.title(for: subject)).tag(option)
						}
					}
				}

				Section("Result") {
					TextField("Score (%)", value: $score, format: .number.precision(.fractionLength(1)))
						.keyboardType(.decimalPad)
					TextField("Semester weighting", value: $weighting, format: .number.precision(.fractionLength(1)))
						.keyboardType(.decimalPad)
					Text("This weighting is calculated within Semester \(semester).")
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
			.appNavigationTitle(assessment == nil ? "New Assessment" : "Edit Assessment")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(role: .cancel) {
						dismiss()
					}
					.disabled(isSaving)
				}
				ToolbarItem(placement: .confirmationAction) {
					Button(assessment == nil ? "Add" : "Save", systemImage: assessment == nil ? "plus" : "checkmark", role: .confirm) {
						Task { await submit() }
					}
					.buttonStyle(.glassProminent)
					.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || weighting <= 0 || isSaving)
				}
			}
			.safeAreaBar(edge: .bottom) {
				if let assessment {
					Button("Delete Assessment", systemImage: "trash", role: .destructive) {
						Task {
							isSaving = true
							await delete(assessment)
							isSaving = false
						}
					}
					.buttonStyle(.glassProminent)
					.tint(.red)
				}
			}
			.onChange(of: date) { _, value in
				let corrected = Self.nearestWeekday(value)
				if corrected != value {
					date = corrected
				}
				if !locationOptions.contains(location) {
					location = locationOptions.first ?? .exam
				}
			}
		}
	}

	private var locationOptions: [GradeAssessmentLocation] {
		var options: [GradeAssessmentLocation] = [.exam]
		guard let day = SchoolCalendarProjection.perthCalendar.dateComponents([.weekday], from: date).weekday,
		      (2 ... 6).contains(day)
		else {
			return options
		}

		let dayIndex = day - 2
		if subjects.contains(where: { subject in
				subject.slots.contains { $0.day == dayIndex }
					&& subject.id.localizedCaseInsensitiveContains("directed study")
			}) {
			options.append(.directedStudy)
		}
		if subject.slots.contains(where: { $0.day == dayIndex }) {
			options.append(.subjectPeriod)
		}
		return options
	}

	private var selectedLocationTitle: String {
		location.title(for: subject)
	}

	private func submit() async {
		isSaving = true
		let proposed = GradeAssessment(
			id: assessment?.id ?? UUID(),
			subjectID: subject.id,
			semester: semester,
			name: name.trimmingCharacters(in: .whitespacesAndNewlines),
			date: SchoolCalendarDate(date),
			score: min(max(score, 0), 100),
			weighting: weighting,
			location: location
		)
		await save(proposed)
		isSaving = false
	}

	private static func nextWeekday() -> Date {
		nearestWeekday(.now)
	}

	private static func nearestWeekday(_ date: Date) -> Date {
		let calendar = SchoolCalendarProjection.perthCalendar
		let weekday = calendar.component(.weekday, from: date)
		if weekday == 7 {
			return calendar.date(byAdding: .day, value: 2, to: date) ?? date
		}
		if weekday == 1 {
			return calendar.date(byAdding: .day, value: 1, to: date) ?? date
		}
		return date
	}
}

private extension GradeAssessmentLocation {
	var symbol: String {
		"checkmark.seal"
	}

	func title(for subject: Subject) -> String {
		switch self {
			case .exam: "Exam"
			case .directedStudy: "Directed Study"
			case .subjectPeriod: subject.id
		}
	}
}
