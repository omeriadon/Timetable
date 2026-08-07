//
//  GradeAssessmentEditor.swift
//  Timetable
//
//  Created by Adon Omeri on 7/8/2026.
//

import SwiftUI

struct GradeAssessmentEditor: View {
	let subject: Subject
	let semester: Int
	let assessment: GradeAssessment?
	let subjects: [Subject]
	let save: (GradeAssessment) async -> Void
	let delete: (GradeAssessment) async -> Void
	@State var name: String
	@State var date: Date
	@State var score: Double
	@State var weighting: Double
	@State var location: GradeAssessmentLocation
	@State var isSaving = false
	@Environment(\.dismiss) var dismiss

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

					HStack {
						Text("Assessment period")
							.foregroundStyle(.secondary)

						Spacer()

						Menu {
							ForEach(locationOptions, id: \.self) { option in
								Button {
									location = option
								} label: {
									Label {
										Text(option.title(for: subject))
										Text(option.subtitle)
									} icon: {
										Image(systemName: "checkmark")
											.opacity(location == option ? 1 : 0)
											.foregroundStyle(location == option ? Color.primary : Color.clear)
									}
								}
							}
						} label: {
							HStack(spacing: 4) {
								Text(location.title(for: subject))

								Image(systemName: "chevron.up.chevron.down")
							}
						}
					}
				}

				Section("Result") {
					HStack {
						Text("Score")
							.foregroundStyle(.secondary)
							.padding(.trailing)

						TextField("Percentage", value: $score, format: .percent.precision(.fractionLength(1)))
							.keyboardType(.decimalPad)
					}

					HStack {
						Text("Weighting")
							.foregroundStyle(.secondary)
							.padding(.trailing)

						TextField("Percentage", value: $weighting, format: .percent.precision(.fractionLength(1)))
							.keyboardType(.decimalPad)
					}
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

	var locationOptions: [GradeAssessmentLocation] {
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

	func submit() async {
		isSaving = true
		let proposed = GradeAssessment(
			id: assessment?.id ?? UUID(),
			subjectID: subject.id,
			semester: semester,
			name: name.trimmingCharacters(in: .whitespacesAndNewlines),
			date: SchoolCalendarDate(date),
			score: min(max(score, 0), 1),
			weighting: weighting,
			location: location
		)
		await save(proposed)
		isSaving = false
	}

	static func nextWeekday() -> Date {
		nearestWeekday(.now)
	}

	static func nearestWeekday(_ date: Date) -> Date {
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
