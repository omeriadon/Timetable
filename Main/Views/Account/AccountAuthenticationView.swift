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
	let allowsSignUp: Bool

	init(allowsSignUp: Bool = true) {
		self.allowsSignUp = allowsSignUp
	}

	var body: some View {
		ScrollView {
			VStack(spacing: 18) {
				if allowsSignUp {
					Picker("Account action", selection: $model.mode) {
						ForEach(AccountAuthenticationMode.allCases) { mode in
							Text(mode.rawValue).tag(mode)
						}
					}
					.pickerStyle(.segmented)
				}

				Spacer()
					.frame(height: 20)

				if model.mode == .signUp {
					AccountInputGroup(
						title: "Name",
						systemImage: "person",
						text: $model.displayName,
						problems: model.displayName.isEmpty ? [] : model.displayNameProblems
					)
					.transition(.blurReplace)
				}

				AccountInputGroup(
					title: "Email",
					systemImage: "envelope",
					text: $model.email,
					problems: model.email.isEmpty ? [] : model.emailProblems
				)

				AccountInputGroup(
					title: "Password",
					systemImage: "lock",
					text: $model.password,
					problems: model.password.isEmpty ? [] : model.passwordProblems,
					isSecure: true
				)

				if model.mode == .signUp {
					AccountInputGroup(
						title: "Confirm Password",
						systemImage: "lock.badge.checkmark",
						text: $model.passwordConfirmation,
						problems: model.passwordConfirmation.isEmpty ? [] : model.passwordConfirmationProblems,
						isSecure: true
					)
					.transition(.blurReplace)
				}

				Spacer()
					.frame(height: 20)

				Button(action: submit) {
					ZStack {
						if model.isSubmitting {
							ProgressView()
								.transition(.blurReplace)
						} else {
							Text(model.mode.rawValue)
								.font(.title3)
								.transition(.blurReplace)
						}
					}
				}
				.buttonSizing(.flexible)
				.animation(.easeInOut(duration: 0.2), value: model.isSubmitting)
				.buttonStyle(.glassProminent)
				.controlSize(.large)
				.frame(maxWidth: .infinity)
				.disabled(model.isSubmitting || !model.isAccountDetailsValid)

				SignInWithAppleButton(.continue) { request in
					request.requestedScopes = [.fullName, .email]
				} onCompletion: { result in
					handleAppleCompletion(result)
				}
				.controlSize(.large)
				.buttonSizing(.flexible)
				.signInWithAppleButtonStyle(.white)
				#if os(iOS)
					.frame(height: 50)
				#endif
					.clipShape(.capsule)
					.disabled(model.isSubmitting)
			}
			.padding(20)
		}
		.scrollDismissesKeyboard(.interactively)
		.appNavigationTitle("Account")
		.animation(reduceMotion ? .none : .snappy, value: "\(model.mode)\(model.problemText)\(model.submissionError ?? "")")
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
