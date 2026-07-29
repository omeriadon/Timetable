import Foundation

struct SubjectTagReplacementProposal: Identifiable {
	let id = UUID()
	let proposedTagIDs: Set<UUID>
	let currentTagNames: [String]
	let proposedTagNames: [String]

	var message: String {
		let current = currentTagNames.isEmpty ? "None" : currentTagNames.joined(separator: ", ")
		let proposed = proposedTagNames.isEmpty ? "None" : proposedTagNames.joined(separator: ", ")
		return """
		Current subject tags: \(current)

		Imported subject tags: \(proposed)

		Year group, sport, general, and other subscriptions are preserved.
		"""
	}
}
