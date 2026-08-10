//
//  GradeSubjectDetailView.swift
//  Timetable
//
//  Created by Adon Omeri on 7/8/2026.
//

import Defaults
import SwiftUI

struct GradeSubjectDetailView: View {
	let subject: Subject
	@Default(.timetable) private var subjects
	@Default(.gradeTracker) private var document
	@State private var service = GradeTrackerService.shared
	@State private var editorContext: AssessmentEditorContext?
	@Environment(\.dismiss) private var dismiss
	@Environment(\.statusBadgeManager) private var badges

	var body: some View {
		NavigationStack {
			List {
				ForEach([1, 2], id: \.self) { semester in
					Section("Semester \(semester)") {
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

						Button {
							editorContext = AssessmentEditorContext(semester: semester)
						} label: {
							Label("New Assessment", systemImage: "plus")
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
				.appPaperPresentation()
			}
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
