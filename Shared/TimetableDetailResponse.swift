//
//  TimetableDetailResponse.swift
//  Shared
//
//  Created by Adon Omeri on 23/7/2026.
//

import Defaults
import Foundation

// Globally shared because I can't be bothered making a new type to save authoerd timeatbls.

nonisolated struct TimetableDetailResponse: Defaults.Serializable, Codable, Identifiable, Hashable {
	let id: UUID
	let title: String
	let authorAccountID: UUID
	let authorDisplayName: String
	let sourceKind: SourceKind
	let subjects: [Subject]
	let subjectCount: Int
	let weeklyLessonCount: Int
	let updatedAt: Date?
	let savedByCount: Int
	let isSearchable: Bool
	let canEdit: Bool
}
