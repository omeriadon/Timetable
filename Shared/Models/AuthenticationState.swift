//
//   AuthenticationState.swift
//   Shared
//
//   Created by Adon Omeri on 28/6/2026.
//

import Foundation

enum AuthenticationState: Equatable {
	case signedOut
	case restoring
	case authenticated(AccountProfile)
}
