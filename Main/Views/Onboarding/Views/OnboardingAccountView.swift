//
//  OnboardingAccountView.swift
//  Timetable
//
//  Created by Adon Omeri on 3/7/2026.
//

import SwiftUI

struct OnboardingAccountView: View {
	@Environment(\.onboardingPageContext) private var context

	var body: some View {
		AccountAuthenticationView()
			.onAppear {
				context.configure(canAdvance: true, statusMessage: "Account creation is optional.")
			}
	}
}
