//
//   AccountAuthenticationView.swift
//   Main
//
//   Created by Adon Omeri on 28/6/2026.
//

import SwiftUI

struct AccountAuthenticationView: View {
	@State private var model = AccountAuthenticationModel()
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	let allowsSignUp: Bool

	init(allowsSignUp: Bool = false) {
		self.allowsSignUp = allowsSignUp
	}

	var body: some View {
		VStack(spacing: 18) {
			if allowsSignUp {
				Picker("Account action", selection: $model.mode) {
					ForEach(AccountAuthenticationMode.allCases) { mode in
						Text(mode.rawValue)
							.tag(mode)
					}
				}
				.pickerStyle(.segmented)
			}

			Spacer()
				.frame(height: 20)

			if model.mode == .signUp, model.verificationRequested {
				AccountInputGroup(
					title: "Verification Code",
					systemImage: "number.square",
					text: $model.verificationCode,
					problems: []
				)

				.keyboardType(.numberPad)

				if let verificationExpiresAt = model.verificationExpiresAt {
					Text("Code expires \(verificationExpiresAt, style: .relative)")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}

				if let resendAvailableAt = model.resendAvailableAt {
					TimelineView(.periodic(from: .now, by: 1)) { context in
						if resendAvailableAt <= context.date {
							Button(action: requestReplacementCode) {
								Label("Send Replacement Code", systemImage: "arrow.clockwise")
							}
							.buttonStyle(.glass)
						} else {
							Text("Replacement available \(resendAvailableAt, style: .relative)")
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
					}
				}
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

			Button(role: model.mode == .signUp && model.verificationRequested ? .confirm : nil, action: submit) {
				ZStack {
					if model.isSubmitting {
						ProgressView()
							.transition(.blurReplace)
					} else {
						Label(
							model.mode == .signUp && !model.verificationRequested ? "Send Code" : model.mode.rawValue,
							systemImage: model.mode == .signUp && !model.verificationRequested ? "envelope.badge" : "checkmark.circle"
						)
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
		}
		.padding(20)
		.appNavigationTitle("Account")
		.animation(reduceMotion ? .none : .snappy, value: "\(model.mode)\(model.problemText)\(model.submissionError ?? "")")
	}

	private func submit() {
		Task {
			await model.submit()
		}
	}

	private func requestReplacementCode() {
		Task {
			await model.requestReplacementCode()
		}
	}
}
