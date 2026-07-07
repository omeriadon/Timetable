import AuthenticationServices
import SwiftUI

struct WatchSignInView: View {
	@Environment(\.statusBadgeManager) private var badges

	@State private var provisioningService = WatchProvisioningService.shared
	@State private var email = ""
	@State private var password = ""
	@State private var isSigningIn = false

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 12) {
				VStack(alignment: .leading, spacing: 8) {
					Text("Sign in on iPhone to sign this Watch in")
						.font(.headline)

					Button {
						provisioningService.requestSessionIfPossible()
					} label: {
						ZStack {
							if provisioningService.isRequesting {
								ProgressView()
									.controlSize(.large)
									.transition(.blurReplace)
							} else {
								Label("Sign In from iPhone", systemImage: "iphone.and.arrow.forward")
									.transition(.blurReplace)
							}
						}
						.frame(height: 50)
						.animation(.easeInOut(duration: 0.2), value: isSigningIn)
					}
					.buttonStyle(.glassProminent)
					.disabled(provisioningService.isRequesting == true)
				}

				Spacer()
					.frame(height: 10)

				Divider()

				Spacer()
					.frame(height: 10)

				Text("Or sign in manually:")
					.font(.caption)

				VStack(spacing: 8) {
					TextField("Email", text: $email)
						.textContentType(.emailAddress)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()

					SecureField("Password", text: $password)
						.textContentType(.password)

					Button {
						Task(priority: .userInitiated) {
							await signIn()
						}
					} label: {
						ZStack {
							if isSigningIn {
								ProgressView()
									.transition(.blurReplace)
							} else {
								Text("Sign In")
									.transition(.blurReplace)
							}
						}
						.animation(.easeInOut(duration: 0.2), value: isSigningIn)
					}
					.disabled(!canSubmit || isSigningIn || provisioningService.isRequesting)
					.frame(height: 40)
					.buttonStyle(.glassProminent)

					SignInWithAppleButton(.signIn) { request in
						request.requestedScopes = [.fullName, .email]
					} onCompletion: { result in
						handleAppleSignIn(result)
					}
					.signInWithAppleButtonStyle(.white)
					.disabled(isSigningIn || provisioningService.isRequesting)
					.clipShape(.capsule)
				}
			}
			.padding()
		}
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Text("Sign In")
					.monospaced()
					.bold()
					.font(.title3)
			}
		}
		.scrollEdgeEffectStyle(.soft, for: .top)
	}

	private var canSubmit: Bool {
		!email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
	}

	private func signIn() async {
		guard canSubmit else {
			badges.addBadge(id: UUID(), title: "Unable to Sign In", secondaryText: "Enter your email and password.", priority: 4, view: .error)
			return
		}

		isSigningIn = true
		defer { isSigningIn = false }

		do {
			try await SessionStore.shared.signIn(
				email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
				password: password,
				context: .userInitiated
			)
		} catch let error as NetworkError {
			guard error != .cancelled else { return }
		} catch {
			badges.present(error: error, title: "Unable to Sign In")
		}

		isSigningIn = false
	}

	private func handleAppleSignIn(_ result: Result<ASAuthorization, any Error>) {
		switch result {
			case let .success(authorization):
				Task(priority: .userInitiated) {
					await completeAppleSignIn(authorization)
				}
			case let .failure(error):
				guard (error as? ASAuthorizationError)?.code != .canceled else { return }
				badges.present(error: error, title: "Unable to Sign In")
		}
	}

	private func completeAppleSignIn(_ authorization: ASAuthorization) async {
		isSigningIn = true
		defer { isSigningIn = false }

		do {
			try await SessionStore.shared.signInWithApple(authorization, context: .userInitiated)
		} catch let error as NetworkError {
			guard error != .cancelled else { return }
		} catch {
			badges.present(error: error, title: "Unable to Sign In")
		}

		isSigningIn = false
	}
}
