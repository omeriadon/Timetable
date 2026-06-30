//
//   AccountAuthenticationView.swift
//   Main
//
//   Created by Adon Omeri on 28/6/2026.
//

import AuthenticationServices
import SwiftUI

struct AccountAuthenticationView: View {
	@State private var model = AccountAuthenticationModel()
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	var body: some View {
		ScrollView {
			VStack(spacing: 18) {
				Picker("Account action", selection: $model.mode) {
					ForEach(AccountAuthenticationMode.allCases) { mode in
						Text(mode.rawValue).tag(mode)
					}
				}
				.pickerStyle(.segmented)

				if model.mode == .signUp {
					AccountInputGroup(
						title: "Name",
						systemImage: "person",
						text: $model.displayName,
						problems: visible(model.displayNameProblems)
					)
					.transition(.blurReplace)
				}

				AccountInputGroup(
					title: "Email",
					systemImage: "envelope",
					text: $model.email,
					problems: visible(model.emailProblems)
				)

				AccountInputGroup(
					title: "Password",
					systemImage: "lock",
					text: $model.password,
					problems: visible(model.passwordProblems),
					isSecure: true
				)

				if model.mode == .signUp {
					AccountInputGroup(
						title: "Confirm Password",
						systemImage: "lock.badge.checkmark",
						text: $model.passwordConfirmation,
						problems: visible(model.passwordConfirmationProblems),
						isSecure: true
					)
					.transition(.blurReplace)
				}

				if let submissionError = model.submissionError {
					ValidationMessagesView(messages: [submissionError])
						.transition(.blurReplace)
				}

				Button(model.mode.rawValue, action: submit)
					.buttonStyle(.borderedProminent)
					.controlSize(.large)
					.frame(maxWidth: .infinity)
					.disabled(model.isSubmitting)

				SignInWithAppleButton(.continue) { request in
					request.requestedScopes = [.fullName, .email]
				} onCompletion: { result in
					handleAppleCompletion(result)
				}
				.signInWithAppleButtonStyle(.whiteOutline)
				.frame(height: 50)
				.clipShape(.capsule)
				.disabled(model.isSubmitting)
			}
			.padding(20)
		}
		.scrollDismissesKeyboard(.interactively)
		.appNavigationTitle("Account")
		.animation(reduceMotion ? .none : .snappy, value: model.mode)
	}

	private func visible(_ problems: [String]) -> [String] {
		model.didAttemptSubmit ? problems : []
	}

	private func submit() {
		Task {
			await model.submit()
		}
	}

	private func handleAppleCompletion(_ result: Result<ASAuthorization, any Error>) {
		switch result {
			case let .success(authorization):
				Task {
					await model.completeAppleAuthorization(authorization)
				}
			case let .failure(error):
				model.handleAppleAuthorizationError(error)
		}
	}
}
