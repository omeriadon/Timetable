import Defaults
import Foundation

nonisolated enum GradeAssessmentLocation: Codable, Hashable, Sendable {
	case exam
	case directedStudy
	case subjectPeriod
}

nonisolated struct GradeAssessment: Codable, Defaults.Serializable, Identifiable, Hashable, Sendable {
	let id: UUID
	let subjectID: String
	let semester: Int
	let name: String
	let date: SchoolCalendarDate
	let score: Double
	let weighting: Double
	let location: GradeAssessmentLocation

	init(
		id: UUID = UUID(),
		subjectID: String,
		semester: Int,
		name: String,
		date: SchoolCalendarDate,
		score: Double,
		weighting: Double,
		location: GradeAssessmentLocation
	) {
		self.id = id
		self.subjectID = subjectID
		self.semester = semester
		self.name = name
		self.date = date
		self.score = score
		self.weighting = weighting
		self.location = location
	}
}

nonisolated struct GradeTrackerDocument: Codable, Defaults.Serializable, Hashable, Sendable {
	var assessments: [GradeAssessment]
	var predictedATAR: Double?
	var goalATAR: Double?
	var serverRevision: Int

	static let empty = GradeTrackerDocument(
		assessments: [],
		predictedATAR: nil,
		goalATAR: nil,
		serverRevision: 0
	)
}

nonisolated struct GradeTrackerUpdateRequest: Codable, Sendable {
	let document: GradeTrackerDocument
	let serverRevision: Int?
}

nonisolated struct GradeTrackerResponse: Codable, Sendable {
	let document: GradeTrackerDocument
}
