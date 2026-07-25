//
//  view extensions.swift
//  Timetable
//
//  Created by Adon Omeri on 25/7/2026.
//

import SwiftUI

extension View {
	@ViewBuilder
	func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
		if condition {
			transform(self)
		} else {
			self
		}
	}

	func modify(@ViewBuilder transform: (Self) -> some View) -> some View {
		transform(self)
	}
}
