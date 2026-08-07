import Defaults
import SwiftUI

struct GradeTrackerView: View {
	@Default(.timetable) var subjects
	@Default(.gradeTracker) var document
	@Default(.eventTagCatalogue) var tagCatalogue
	@Default(.eventTagSubscriptionIDs) var subscriptionIDs
	@State var service = GradeTrackerService.shared
	@State var selectedSubject: Subject?
	@State var showsATARSheet = false
	@Environment(\.accessibilityReduceMotion) var reduceMotion

	var body: some View {
		NavigationStack {
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
						let reduceMotionValue = reduceMotion

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
									.opacity(reduceMotionValue || phase.isIdentity ? 1 : 0.65)
									.scaleEffect(reduceMotionValue || phase.isIdentity ? 1 : 0.96)
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
	}

	var isSenior: Bool {
		let yearGroupTags = tagCatalogue.sections
			.filter { $0.category == .yearGroup }
			.flatMap(\.tags)
			.filter { subscriptionIDs.contains($0.id) }

		return yearGroupTags.contains { tag in
			let name = tag.displayName.lowercased()
			return name.contains("11") || name.contains("12")
		}
	}

	var averageCard: some View {
		GradeAverageCard(
			average: overallAverage,
			predictedATAR: document.predictedATAR,
			goalATAR: document.goalATAR,
			showsATAR: isSenior
		)
	}

	var overallAverage: Double? {
		let averages = subjects.compactMap { subjectAverage(for: $0.id) }
		guard !averages.isEmpty else {
			return nil
		}
		return averages.reduce(0, +) / Double(averages.count)
	}

	func subjectAverage(for subjectID: String) -> Double? {
		let assessments = document.assessments.filter { $0.subjectID == subjectID }
		let totalWeight = assessments.reduce(0) { $0 + $1.weighting }
		guard totalWeight > 0 else {
			return nil
		}
		return assessments.reduce(0) { $0 + ($1.score * $1.weighting) } / totalWeight
	}
}

struct GradeAverageCard: View {
	let average: Double?
	let predictedATAR: Double?
	let goalATAR: Double?
	let showsATAR: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			HStack(alignment: .center, spacing: 18) {
				GradeGauge(value: average)
					.tint(.black)

				VStack(alignment: .leading, spacing: 4) {
					Text("Overall Average")
						.font(.headline.weight(.semibold))
						.foregroundStyle(.secondary)

					if let average {
						Text(average, format: .percent.precision(.fractionLength(1)))
							.font(.title)
					} else {
						Text("No assessments yet")
							.font(.title)
					}
				}
			}

			if showsATAR {
				VStack {
					HStack {
						Text("Predicted ATAR")
						Spacer()
						Text("Goal ATAR")
						Spacer()
						Text("Gap")
					}
					.font(.caption)
					.foregroundStyle(.secondary)

					HStack {
						Text(predictedATAR.map { "\($0, specifier: "%.2f")" } ?? "Not set")
						Spacer()
						Text(goalATAR.map { "\($0, specifier: "%.2f")" } ?? "Not set")
						Spacer()
						Text({
							guard let goal = goalATAR, let predicted = predictedATAR else { return "Not set" }
							return String(format: "%.2f", goal - predicted)
						}())
					}
					.font(.headline)
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

struct GradeSubjectCard: View {
	let subject: Subject
	let average: Double?

	var body: some View {
		HStack(spacing: 14) {
			GradeGauge(value: average, tint: subject.colour.swiftUIColor)

			VStack(alignment: .leading, spacing: 5) {
				Text(subject.id)
					.font(.title3.weight(.semibold))
				if let average {
					Text("\(average, format: .percent.precision(.fractionLength(1))) average")
				} else {
					Text("No assessments yet")
				}
			}

			Spacer()
		}
		.foregroundStyle(.secondary)
		.padding(14)
		.background(FriendPaperBackground(cornerRadius: 28))
		.glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
		.foregroundStyle(.black)
	}
}

struct GradeGauge: View {
	let value: Double?
	var tint: Color = .brown

	var body: some View {
		Gauge(value: value ?? 0, in: 0 ... 1) {
			Image(systemName: "chart.line.uptrend.xyaxis")
		} currentValueLabel: {
			if let value {
				Text(value, format: .percent.precision(.fractionLength(0)))
					.font(.caption.bold())
			} else {
				Text("—")
					.font(.caption.bold())
			}
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

struct ATARSettingsSheet: View {
	@Default(.gradeTracker) var document
	@State var predictedATAR: Double?
	@State var goalATAR: Double?
	@State var service = GradeTrackerService.shared
	@Environment(\.dismiss) var dismiss
	@Environment(\.statusBadgeManager) var badges

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

	func save() async {
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

struct AssessmentEditorContext: Identifiable {
	let id = UUID()
	let semester: Int
	let assessment: GradeAssessment?

	init(semester: Int, assessment: GradeAssessment? = nil) {
		self.semester = semester
		self.assessment = assessment
	}
}

struct GradeAssessmentRow: View {
	let assessment: GradeAssessment

	var body: some View {
		HStack(alignment: .lastTextBaseline, spacing: 14) {
			GradeGauge(value: assessment.score, tint: .brown)

			VStack(alignment: .leading, spacing: 4) {
				Text(assessment.name)
					.font(.title3)
				Text(assessment.date.displayLabel)
					.font(.caption)
					.foregroundStyle(.secondary)
			}

			Spacer()

			VStack(alignment: .trailing, spacing: 4) {
				Text(assessment.score, format: .percent.precision(.fractionLength(1)))
					.font(.title2)
				Text("Weighting: \(assessment.weighting, format: .percent.precision(.fractionLength(1)))")
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		}
	}
}
