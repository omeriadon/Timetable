//
//   AccountAuthenticationModel.swift
//   Main
//
//   Created by Adon Omeri on 28/6/2026.
//

import Foundation
import Observation

enum AccountAuthenticationMode: String, CaseIterable, Identifiable {
	case signIn = "Sign In"
	case signUp = "Sign Up"

	var id: Self {
		self
	}
}

@MainActor
@Observable
final class AccountAuthenticationModel {
	var mode: AccountAuthenticationMode = .signIn {
		didSet {
			didAttemptSubmit = false
			submissionError = nil
			passwordConfirmation = ""
		}
	}

	var displayName = ""
	var email = ""
	var password = ""
	var passwordConfirmation = ""
	var verificationCode = ""
	private(set) var verificationRequested = false
	private(set) var isSubmitting = false
	private(set) var didAttemptSubmit = false
	private(set) var submissionError: String?

	private let sessionStore: SessionStore

	init(sessionStore: SessionStore? = nil) {
		self.sessionStore = sessionStore ?? .shared
	}

	var displayNameProblems: [String] {
		guard mode == .signUp else { return [] }
		var problems: [String] = []
		let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

		if trimmed.count > 30 {
			problems.append("Your name must contain 30 characters or fewer.")
		}
		return problems
	}

	var emailProblems: [String] {
		var problems: [String] = []
		let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

		if !trimmed.contains("@") || trimmed.hasPrefix("@") || trimmed.hasSuffix("@") {
			problems.append("Enter a valid email address.")
		}
		if trimmed.count > 45 {
			problems.append("Your email must contain 45 characters or fewer.")
		}
		return problems
	}

	var passwordProblems: [String] {
		var problems: [String] = []
		if mode == .signUp, !password.isEmpty, password.count < 8 {
			problems.append("Use at least eight characters.")
		}
		return problems
	}

	var passwordConfirmationProblems: [String] {
		guard mode == .signUp else { return [] }
		var problems: [String] = []
		if !passwordConfirmation.isEmpty, passwordConfirmation != password {
			problems.append("The passwords do not match.")
		}
		return problems
	}

	func submit() async {
		didAttemptSubmit = true
		submissionError = nil
		guard allProblems.isEmpty else { return }

		isSubmitting = true
		defer { isSubmitting = false }

		do {
			switch mode {
				case .signIn:
					try await sessionStore.signIn(email: normalizedEmail, password: password)
				case .signUp:
					if verificationRequested {
						try await sessionStore.verifyCodeAndSignUp(email: normalizedEmail, code: verificationCode, password: password)
					} else {
						try await sessionStore.requestVerificationCode(email: normalizedEmail)
						verificationRequested = true
					}
			}
		} catch {
			StatusBadgeManager.shared.addBadge(id: UUID(), title: "Unable to Sign in", secondaryText: error.localizedDescription, priority: 5, view: .error)
			submissionError = error.localizedDescription
		}
	}

	private var normalizedEmail: String {
		email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
	}

	private var allProblems: [String] {
		displayNameProblems + emailProblems + passwordProblems + passwordConfirmationProblems
	}

	var problemText: String {
		allProblems.joined()
	}

	var isAccountDetailsValid: Bool {
		allProblems.isEmpty && (mode != .signUp || !verificationRequested || verificationCode.count == 6)
	}
}
